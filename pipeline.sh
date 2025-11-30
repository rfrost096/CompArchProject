
# This script should be run from within CompArchProject/chipyard/sims/verilator
BINARY_NAME="multiplication_boom"

CONFIG_LIST=(
    "64 4 8 medium medium medium TAGELBPD"
    "64 4 8 medium large  medium TAGELBPD"
)

CACHE_LINE_SIZE_OPTIONS=(32 64 128)
CACHE_ASSOCIATIVITY_OPTIONS=(2 4)
NUM_TLB_WAYS_OPTIONS=(4 8 12)
FRONTEND_WIDTH_OPTIONS=("small" "medium" "large" "mega")
SUPER_SCALAR_WIDTH_OPTIONS=("small" "medium" "large" "mega")
WORKING_WINDOW_WIDTH_OPTIONS=("small" "medium" "large" "mega")
BRANCH_PREDICTOR_OPTIONS=("TAGELBPD" "Boom2BPD" "Alpha21264BPD" "SWBPD")

PROJECT_DIRECTORY="../../../"

BINARY_PATH="${PROJECT_DIRECTORY}/binaries/${BINARY_NAME}.riscv"

OUTPUT_DIRECTORY="${PROJECT_DIRECTORY}output/"

BINARY_OUTPUT_DIRECTORY="${OUTPUT_DIRECTORY}${BINARY_NAME}/"

VERIFY_DIRECTORY="${BINARY_OUTPUT_DIRECTORY}verify/"
VERIFY_RESULTS_FILE="${VERIFY_DIRECTORY}results.txt"
VERIFY_LOGS_DIRECTORY="${VERIFY_DIRECTORY}logs"
VERIFY_LOG_PREFIX="verify_log_"

CONFIG_HISTORY_DIRECTORY="${OUTPUT_DIRECTORY}config_history/"
VERIFY_SUCCEED_CONFIGS_FILE="${CONFIG_HISTORY_DIRECTORY}succeeded_configs.txt"
VERIFY_FAILED_CONFIGS_FILE="${CONFIG_HISTORY_DIRECTORY}failed_configs.txt"

mkdir -p "$VERIFY_LOGS_DIRECTORY"
mkdir -p "$CONFIG_HISTORY_DIRECTORY"

touch "$VERIFY_SUCCEED_CONFIGS_FILE"
touch "$VERIFY_FAILED_CONFIGS_FILE"

rm -f "$VERIFY_RESULTS_FILE" "$VERIFY_LOGS_DIRECTORY"/"$VERIFY_LOG_PREFIX"*.txt

RUN_DIRECTORY="${BINARY_OUTPUT_DIRECTORY}run/"
RUN_RESULTS_FILE="${RUN_DIRECTORY}results.txt"
RUN_LOGS_DIRECTORY="${RUN_DIRECTORY}logs"
RUN_LOG_PREFIX="run_log_"

mkdir -p "$RUN_LOGS_DIRECTORY"

rm -f "$RUN_RESULTS_FILE" "$RUN_LOGS_DIRECTORY"/"$RUN_LOG_PREFIX"*.txt

validate_options() {

    echo "validating options$CONFIG_NAME"

    check_param() {
        local name="$1"
        local value="$2"
        shift 2
        local options=("$@")
        local valid=false

        for option in "${options[@]}"; do
            if [[ "$option" == "$value" ]]; then
                valid=true
                break
            fi
        done

        if [[ "$valid" == "false" ]]; then
            echo "ERROR validation failed$CONFIG_NAME"
            echo "PARAM: $name"
            echo "VALUE: $value"
            echo "OPTIONS: ${options[*]}"
            exit 1
        fi
    }

    check_param "CACHE_LINE_SIZE"      "$CACHE_LINE_SIZE_PARAM"      "${CACHE_LINE_SIZE_OPTIONS[@]}"
    check_param "CACHE_ASSOCIATIVITY"  "$CACHE_ASSOCIATIVITY_PARAM"  "${CACHE_ASSOCIATIVITY_OPTIONS[@]}"
    check_param "NUM_TLB_WAYS"         "$NUM_TLB_WAYS_PARAM"         "${NUM_TLB_WAYS_OPTIONS[@]}"
    check_param "FRONTEND_WIDTH"       "$FRONTEND_WIDTH_PARAM"       "${FRONTEND_WIDTH_OPTIONS[@]}"
    check_param "SUPER_SCALAR_WIDTH"   "$SUPER_SCALAR_WIDTH_PARAM"   "${SUPER_SCALAR_WIDTH_OPTIONS[@]}"
    check_param "WORKING_WINDOW_WIDTH" "$WORKING_WINDOW_WIDTH_PARAM" "${WORKING_WINDOW_WIDTH_OPTIONS[@]}"
    check_param "BRANCH_PREDICTOR"     "$BRANCH_PREDICTOR_PARAM"     "${BRANCH_PREDICTOR_OPTIONS[@]}"
}

verify_config() {

    if ! grep -q "ID: $CONFIG_ID" "$VERIFY_SUCCEED_CONFIGS_FILE"; then

        echo "verifying config$CONFIG_NAME"

        if make -B CONFIG=ModularBoomConfig firrtl > "$VERIFY_LOGS_DIRECTORY/${VERIFY_LOG_PREFIX}${CONFIG_ID}.txt" 2>&1; then
            echo "verify succeded$CONFIG_NAME" >> "$VERIFY_RESULTS_FILE"

            if ! grep -q "ID: $CONFIG_ID" "$VERIFY_SUCCEED_CONFIGS_FILE"; then
                {
                    echo "DATE: $(date)"
                    echo "ID: $CONFIG_ID"
                    echo "CONFIG:$CONFIG_NAME"
                    echo "----" 
                } >> "$VERIFY_SUCCEED_CONFIGS_FILE"
            fi
        else
            echo "verify failed$CONFIG_NAME"
            echo "verify failed$CONFIG_NAME" >> "$VERIFY_RESULTS_FILE"
            
            if ! grep -q "ID: $CONFIG_ID" "$VERIFY_FAILED_CONFIGS_FILE"; then
                {
                    echo "DATE: $(date)"
                    echo "ID: $CONFIG_ID"
                    echo "CONFIG:$CONFIG_NAME"
                    echo "----" 
                } >> "$VERIFY_FAILED_CONFIGS_FILE"
            fi

            exit 1
        fi
    else
        echo "assuming verify succeeded based on previous run$CONFIG_NAME"
        echo "verify succeded\n$CONFIG_NAME\n" >> "$VERIFY_RESULTS_FILE"
    fi
}

run_analysis() {
    echo "running$CONFIG_NAME"

    local RUN_LOG="${RUN_LOGS_DIRECTORY}/${RUN_LOG_PREFIX}${CONFIG_ID}.txt"

    make -B CONFIG=ModularBoomConfig -j4 run-binary BINARY=$(realpath "$BINARY_PATH") > "$RUN_LOG" 2>&1

    if grep -q "\[UART\] UART0 is here (stdin/stdout)\." "$RUN_LOG"; then
        {
            echo "analysis for$CONFIG_NAME"

            sed '0,/\[UART\] UART0 is here (stdin\/stdout)\./d' "$RUN_LOG" | sed -e 's/-.*//' -e '/-/q'

            echo -e "\n"
        } >> "$RUN_RESULTS_FILE"
    else
        echo "run failed\n$CONFIG_NAME"
        {
            echo "analysis for$CONFIG_NAME"
            echo -e "failed to parse log file for output\n\n"
        } >> "$RUN_RESULTS_FILE"
        exit 1
    fi
}

load_config_env() {
    set -- $config

    export CACHE_LINE_SIZE_PARAM=$1
    export CACHE_ASSOCIATIVITY_PARAM=$2
    export NUM_TLB_WAYS_PARAM=$3
    export FRONTEND_WIDTH_PARAM=$4
    export SUPER_SCALAR_WIDTH_PARAM=$5
    export WORKING_WINDOW_WIDTH_PARAM=$6
    export BRANCH_PREDICTOR_PARAM=$7

    CONFIG_ID="${1}_${2}_${3}_${4}_${5}_${6}_${7}"
    CONFIG_NAME="
    CACHE_LINE_SIZE:$CACHE_LINE_SIZE_PARAM, 
    CACHE_ASSOCIATIVITY:$CACHE_ASSOCIATIVITY_PARAM, 
    NUM_TLB_WAYS:$NUM_TLB_WAYS_PARAM, 
    FRONTEND_WIDTH:$FRONTEND_WIDTH_PARAM, 
    SUPER_SCALAR_WIDTH:$SUPER_SCALAR_WIDTH_PARAM, 
    WORKING_WINDOW_WIDTH:$WORKING_WINDOW_WIDTH_PARAM, 
    BRANCH_PREDICTOR:$BRANCH_PREDICTOR_PARAM
"
}

for config in "${CONFIG_LIST[@]}"; do
    load_config_env "$config"
    validate_options
done

for config in "${CONFIG_LIST[@]}"; do
    load_config_env "$config"
    verify_config
done

for config in "${CONFIG_LIST[@]}"; do
    load_config_env "$config"
    run_analysis
done
