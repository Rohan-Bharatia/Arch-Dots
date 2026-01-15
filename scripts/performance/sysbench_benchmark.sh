#!/bin/bash

set -o nounset
set -o pipefail

readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly BLUE=$'\033[0;34m'
readonly YELLOW=$'\033[1;33m'
readonly CYAN=$'\033[0;36m'
readonly BOLD=$'\033[1m'
readonly NC=$'\033[0m'
readonly TOTAL_CORES=$(nproc)

ACTIVE_THREADS=$TOTAL_CORES
TASKSET_CMD=()
RUN_TIME=10

cleanup() {
    echo -e "\n${YELLOW}Benchmark stopped by user.${NC}"
    exit 130
}
trap cleanup INT TERM

check_deps() {
    local missing_deps=0
    local cmd
    for cmd in sysbench taskset lscpu awk nproc; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${RED}Error: Required command '$cmd' is missing.${NC}"
            missing_deps=1
        fi
    done
    if [[ $missing_deps -eq 1 ]]; then
        echo -e "\n${YELLOW}Install missing dependencies:${NC}"
        echo -e "  Arch/Manjaro:  ${CYAN}sudo pacman -S sysbench util-linux gawk${NC}"
        echo -e "  Debian/Ubuntu: ${CYAN}sudo apt install sysbench util-linux gawk${NC}"
        echo -e "  Fedora/RHEL:   ${CYAN}sudo dnf install sysbench util-linux gawk${NC}"
        echo -e "  openSUSE:      ${CYAN}sudo zypper install sysbench util-linux gawk${NC}"
        exit 1
    fi
}

print_header() {
    clear
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${BOLD}        SYSBENCH ULTIMATE DASHBOARD v14.1                  ${NC}"
    echo -e "${CYAN}============================================================${NC}"
    local cpu_model
    cpu_model=$(LC_ALL=C lscpu 2>/dev/null | grep -m1 "Model name" | cut -d: -f2 | xargs 2>/dev/null) || true
    if [[ -z "$cpu_model" ]]; then
        cpu_model=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs 2>/dev/null) || true
    fi
    echo -e "System: ${BOLD}${cpu_model:-Unknown CPU}${NC}"
    echo -e "Logical Cores: ${BOLD}${TOTAL_CORES}${NC}"
    echo -e "${CYAN}------------------------------------------------------------${NC}"
}

calc_threads() {
    local input="$1"
    local count=0
    local item start end
    local list="${input//,/ }"
    for item in $list; do
        if [[ "$item" == *"-"* ]]; then
            start="${item%-*}"
            end="${item#*-}"
            if [[ "$start" =~ ^[0-9]+$ ]] && [[ "$end" =~ ^[0-9]+$ ]]; then
                if ((start > end)); then
                    ((count += start - end + 1))
                else
                    ((count += end - start + 1))
                fi
            fi
        elif [[ "$item" =~ ^[0-9]+$ ]]; then
            ((count++))
        fi
    done
    ((count < 1)) && count=1
    printf '%d' "$count"
}

select_cores() {
    local core_opt core_range last_core
    while true; do
        echo -e "\n${YELLOW}--- Core Selection ---${NC}"
        echo -e "1) ${GREEN}All Cores${NC} (Default)"
        echo -e "2) ${GREEN}Core 0 Only${NC} (P-Core Test)"
        echo -e "3) ${GREEN}Last Core Only${NC} (E-Core Test)"
        echo -e "4) ${GREEN}Custom Range${NC} (e.g., 0-3 or 0,2,4)"
        echo -e "q) ${RED}Cancel${NC}"
        echo -n "Select option [1]: "
        read -r core_opt
        [[ -z "$core_opt" ]] && core_opt="1"
        case "$core_opt" in
            q|Q)
                return 1
                ;;
            1)
                TASKSET_CMD=()
                ACTIVE_THREADS=$TOTAL_CORES
                echo -e "${BLUE}>> Using All Cores (Threads: $ACTIVE_THREADS)${NC}"
                return 0
                ;;
            2)
                TASKSET_CMD=(taskset -c 0)
                ACTIVE_THREADS=1
                echo -e "${BLUE}>> Pinned to Core 0 (Threads: 1)${NC}"
                return 0
                ;;
            3)
                last_core=$((TOTAL_CORES - 1))
                TASKSET_CMD=(taskset -c "$last_core")
                ACTIVE_THREADS=1
                echo -e "${BLUE}>> Pinned to Core $last_core (Threads: 1)${NC}"
                return 0
                ;;
            4)
                echo -n "Enter core list (e.g., 0-3 or 0,2,4): "
                read -r core_range
                if [[ -z "$core_range" ]]; then
                    echo -e "${RED}Error: No cores specified.${NC}"
                    continue
                fi
                if ! taskset -c "$core_range" true 2>/dev/null; then
                    echo -e "${RED}Error: Invalid core list or cores out of range.${NC}"
                    continue
                fi
                TASKSET_CMD=(taskset -c "$core_range")
                ACTIVE_THREADS=$(calc_threads "$core_range")
                echo -e "${BLUE}>> Using cores '$core_range' (Threads: $ACTIVE_THREADS)${NC}"
                return 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1-4 or q.${NC}"
                ;;
        esac
    done
}

select_duration() {
    local time_opt custom_time
    while true; do
        echo -e "\n${YELLOW}--- Duration Selection ---${NC}"
        echo -e "1) ${GREEN}10 Seconds${NC} (Default)"
        echo -e "2) ${GREEN}1 Minute${NC} (Stability)"
        echo -e "3) ${GREEN}Custom Time${NC}"
        echo -e "q) ${RED}Cancel${NC}"
        echo -n "Select option [1]: "
        read -r time_opt
        [[ -z "$time_opt" ]] && time_opt="1"
        case "$time_opt" in
            q|Q)
                return 1
                ;;
            1)
                RUN_TIME=10
                echo -e "${BLUE}>> Duration: 10s${NC}"
                return 0
                ;;
            2)
                RUN_TIME=60
                echo -e "${BLUE}>> Duration: 60s${NC}"
                return 0
                ;;
            3)
                echo -n "Enter seconds (1-86400): "
                read -r custom_time
                if [[ "$custom_time" =~ ^[0-9]+$ ]] && \
                   ((custom_time >= 1 && custom_time <= 86400)); then
                    RUN_TIME=$custom_time
                    echo -e "${BLUE}>> Duration: ${RUN_TIME}s${NC}"
                    return 0
                else
                    echo -e "${RED}Invalid time. Please enter a number between 1 and 86400.${NC}"
                fi
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1-3 or q.${NC}"
                ;;
        esac
    done
}

run_sysbench() {
    local test_type="$1"
    shift
    if ((${#TASKSET_CMD[@]} > 0)); then
        "${TASKSET_CMD[@]}" sysbench "$test_type" "$@"
    else
        sysbench "$test_type" "$@"
    fi
}

menu_cpu() {
    print_header
    echo -e "${BOLD}CPU BENCHMARK${NC}"
    echo -e "Calculating Primes up to 50,000."
    if ! select_cores; then return; fi
    if ! select_duration; then return; fi
    echo -e "\n${YELLOW}Starting Benchmark...${NC}"
    sleep 1
    run_sysbench cpu \
        --cpu-max-prime=50000 \
        --threads="$ACTIVE_THREADS" \
        --time="$RUN_TIME" \
        --events=0 \
        --report-interval=1 \
        run
    echo ""
    read -r -p "Press Enter to return..."
}

menu_memory() {
    print_header
    echo -e "${BOLD}MEMORY BENCHMARK${NC}"
    local oper="read"
    local block_size="16M"
    local access_mode="seq"
    local scope="local"
    local mem_opt
    while true; do
        echo -e "\n${YELLOW}--- Memory Test Mode ---${NC}"
        echo "1) Sequential Read (Large Blocks - Max Bandwidth)"
        echo "2) Random Read (Small Blocks - Latency/IOPS)"
        echo "3) Sequential Write"
        echo -e "q) ${RED}Back${NC}"
        echo -n "Select Mode [1]: "
        read -r mem_opt
        [[ -z "$mem_opt" ]] && mem_opt="1"
        case "$mem_opt" in
            q|Q)
                return
                ;;
            1)
                oper="read"
                block_size="64M"
                access_mode="seq"
                scope="local"
                echo -e "${BLUE}>> Mode: Sequential Read (64M Blocks - Local Scope)${NC}"
                break
                ;;
            2)
                oper="read"
                block_size="4K"
                access_mode="rnd"
                scope="global"
                echo -e "${BLUE}>> Mode: Random Read (4K Blocks - Global Scope)${NC}"
                break
                ;;
            3)
                oper="write"
                block_size="64M"
                access_mode="seq"
                scope="local"
                echo -e "${BLUE}>> Mode: Sequential Write (64M Blocks - Local Scope)${NC}"
                break
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1-3 or q.${NC}"
                ;;
        esac
    done
    if ! select_cores; then
        return
    fi
    if ! select_duration; then
        return
    fi
    echo -e "\n${YELLOW}Starting Benchmark...${NC}"
    sleep 1
    run_sysbench memory \
        --memory-block-size="$block_size" \
        --memory-access-mode="$access_mode" \
        --memory-scope="$scope" \
        --memory-total-size=500G \
        --memory-oper="$oper" \
        --threads="$ACTIVE_THREADS" \
        --time="$RUN_TIME" \
        --events=0 \
        --report-interval=1 \
        run

    echo ""
    read -r -p "Press Enter to return..."
}

menu_threads() {
    print_header
    echo -e "${BOLD}THREADS (SCHEDULER) BENCHMARK${NC}"
    echo -e "Testing kernel scheduler performance with thread contention."
    if ! select_cores; then
        return
    fi
    if ! select_duration; then
        return
    fi
    echo -e "\n${YELLOW}Starting Benchmark...${NC}"
    sleep 1
    run_sysbench threads \
        --thread-locks=1 \
        --threads="$ACTIVE_THREADS" \
        --time="$RUN_TIME" \
        --events=0 \
        --report-interval=1 \
        run
    echo ""
    read -r -p "Press Enter to return..."
}

local choice
check_deps
while true; do
    print_header
    echo "1) CPU Speedometer"
    echo "2) RAM Speedometer (Bandwidth/Latency)"
    echo "3) Scheduler Latency"
    echo -e "q) ${RED}Quit${NC}"
    echo -e "${CYAN}------------------------------------------------------------${NC}"
    echo -n "Select: "
    read -r choice
    case "$choice" in
        1)
            menu_cpu
            ;;
        2)
            menu_memory
            ;;
        3)
            menu_threads
            ;;
        q|Q)
            echo -e "${YELLOW}Exiting. Goodbye!${NC}"
            exit 0
            ;;
        "")
            ;;
        *)
            echo -e "${RED}Invalid option '$choice'. Press Enter to continue...${NC}"
            read -r
            ;;
    esac
done
