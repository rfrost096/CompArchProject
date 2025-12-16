
# This script should be run from within CompArchProject/chipyard/sims/verilator
BINARY_NAME="aes"

CONFIG_LIST=(
    "64 4 4 medium medium medium TAGELBPD"
    
    "64 4 8 small small small TAGELBPD"

    "64 4 8 small medium small TAGELBPD"
    
    "64 4 8 small medium medium TAGELBPD"
    "64 4 8 medium medium small TAGELBPD"

    "64 4 8 medium medium medium TAGELBPD"

    "64 4 8 medium large medium TAGELBPD"

    "64 4 8 medium large large TAGELBPD"
    "64 4 8 large large medium TAGELBPD"

    "64 4 8 large large large TAGELBPD"

    "64 4 8 small small small Boom2BPD"

    "64 4 8 small small small TAGELBPD"
    "64 2 8 small small small TAGELBPD"
    "32 4 8 small small small TAGELBPD"
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

CONFIG_DIRECTORY="${OUTPUT_DIRECTORY}config/"

VERIFY_SUCCEED_CONFIGS_FILE="${CONFIG_DIRECTORY}succeeded_configs.txt"
VERIFY_FAILED_CONFIGS_FILE="${CONFIG_DIRECTORY}failed_configs.txt"
VERIFY_LOGS_DIRECTORY="${CONFIG_DIRECTORY}verify_logs"
VERIFY_LOG_PREFIX="verify_log_"

mkdir -p "$VERIFY_LOGS_DIRECTORY"

touch "$VERIFY_SUCCEED_CONFIGS_FILE"
touch "$VERIFY_FAILED_CONFIGS_FILE"

VERILOG_LOGS_DIRECTORY="${CONFIG_DIRECTORY}verilog_logs"
VERILOG_LOGS_PREFIX="verilog_log_"

mkdir -p "$VERILOG_LOGS_DIRECTORY"

CONFIG_SIZE_FILE="${CONFIG_DIRECTORY}config_sizes.txt"
CONFIG_SIZE_LOGS_DIRECTORY="${CONFIG_DIRECTORY}size_logs"
CONFIG_SIZE_PREFIX="size_log_"

mkdir -p "$CONFIG_SIZE_LOGS_DIRECTORY"

touch "$CONFIG_SIZE_FILE"

RUN_RESULTS_FILE="${BINARY_OUTPUT_DIRECTORY}results.txt"
RUN_LOGS_DIRECTORY="${BINARY_OUTPUT_DIRECTORY}logs"
RUN_LOG_PREFIX="run_log_"

mkdir -p "$RUN_LOGS_DIRECTORY"

touch "$RUN_RESULTS_FILE"

VERILOG_DIRECTORY="${PROJECT_DIRECTORY}/chipyard/sims/verilator/generated-src/chipyard.harness.TestHarness.ModularBoomConfig/gen-collateral"
SIZE_VERILOG_DIRECTORY="${PROJECT_DIRECTORY}/chipyard/sims/verilator/generated-src/chipyard.harness.TestHarness.ModularBoomConfig/gen-collateral-size"
YS_SCRIPT="${PROJECT_DIRECTORY}synth.ys"

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

        local CONFIG_LOG="$VERIFY_LOGS_DIRECTORY/${VERIFY_LOG_PREFIX}${CONFIG_ID}.txt"

        rm -f "$CONFIG_LOG"

        if make -B CONFIG=ModularBoomConfig firrtl > "$CONFIG_LOG" 2>&1; then
            echo "verify succeded$CONFIG_NAME"
            {
                echo "DATE: $(date)"
                echo "ID: $CONFIG_ID"
                echo "CONFIG:$CONFIG_NAME"
                echo "----" 
            } >> "$VERIFY_SUCCEED_CONFIGS_FILE"
        else
            echo "verify failed$CONFIG_NAME"
            
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
    fi
}

run_analysis() {

    if ! grep -q "ID: $CONFIG_ID" "$RUN_RESULTS_FILE"; then

        echo "running$CONFIG_NAME"

        local RUN_LOG="${RUN_LOGS_DIRECTORY}/${RUN_LOG_PREFIX}${CONFIG_ID}.txt"

        rm -f $RUN_LOG

        make -B CONFIG=ModularBoomConfig -j4 run-binary BINARY=$(realpath "$BINARY_PATH") > "$RUN_LOG" 2>&1

        if grep -q "\[UART\] UART0 is here (stdin/stdout)\." "$RUN_LOG"; then
            echo "run succeeded\n$CONFIG_NAME"
            {
                echo "DATE: $(date)"
                echo "ID: $CONFIG_ID"
                echo "CONFIG:$CONFIG_NAME"

                sed '0,/\[UART\] UART0 is here (stdin\/stdout)\./d' "$RUN_LOG" | sed -e 's/-.*//' -e '/-/q'

                echo -e "\n----" 
            } >> "$RUN_RESULTS_FILE"
        else
            echo "run failed\n$CONFIG_NAME"
            {
                echo "analysis for$CONFIG_NAME"
                echo -e "failed to parse log file for output\n\n"
            } >> "$RUN_RESULTS_FILE"
            exit 1
        fi
    else
        echo "Config workload combination already analyzed$CONFIG_NAME"
    fi
}

size_analysis() {

    if ! grep -q "ID: $CONFIG_ID" "$CONFIG_SIZE_FILE"; then

        echo "size analysis$CONFIG_NAME"

        local VERILOG_LOG="${VERILOG_LOGS_DIRECTORY}/${VERILOG_LOG_PREFIX}${CONFIG_ID}.txt"

        rm -f $VERILOG_LOG

        make -B CONFIG=ModularBoomConfig verilog > "$VERILOG_LOG" 2>&1

        rm -rf $SIZE_VERILOG_DIRECTORY

        cp -r $VERILOG_DIRECTORY $SIZE_VERILOG_DIRECTORY

        find "$SIZE_VERILOG_DIRECTORY" -type f \( -name "*.sv" -o -name "*.v" \) -exec sed -i "s/'{/{/g" {} +

        rm $YS_SCRIPT

        cat <<EOF >> "$YS_SCRIPT"
read_verilog -sv -D SYNTHESIS $SIZE_VERILOG_DIRECTORY/*.sv
read_verilog -D SYNTHESIS $SIZE_VERILOG_DIRECTORY/*.v
hierarchy -top DigitalTop
synth
abc -g cmos2
stat
EOF

        RM_FILE_LIST=("ClockSourceAtFreqMHz.v" "SimDRAM.v" "SimJTAG.v" "SimTSI.v" "SimUART.v" "TestDriver.v")

        for file in "${RM_FILE_LIST[@]}"; do 
            rm "${SIZE_VERILOG_DIRECTORY}/${file}"
        done

        local SIZE_LOG="${CONFIG_SIZE_LOGS_DIRECTORY}/${CONFIG_SIZE_PREFIX}${CONFIG_ID}.txt"

        rm -f "$SIZE_LOG"

        CONDA_ENV_PATH=""

        if [ "$USER" == "rfrost26" ]; then
            CONDA_ENV_PATH="/home/rfrost26/.conda/envs/yosys_env"
        elif [ "$USER" == "ryan" ]; then
            CONDA_ENV_PATH="/home/ryan/miniforge3/envs/yosys_env"
        else
            echo "user $USER Yosys path not defined" >&2
            exit 1
        fi

        conda run --no-capture-output -p $CONDA_ENV_PATH yosys $YS_SCRIPT > "$SIZE_LOG" 2>&1

        if grep -q "=== design hierarchy ===" "$SIZE_LOG"; then
            echo "size analysis succeeded$CONFIG_NAME"

            {
                echo "DATE: $(date)"
                echo "ID: $CONFIG_ID"
                echo "CONFIG:$CONFIG_NAME"

                awk '/=== design hierarchy ===/{flag=1; buf=""} flag && /Warnings/{flag=0; last=buf} flag{buf=buf $0 ORS} END{printf "%s", last}' "$SIZE_LOG"

                echo -e "\n----\n\n" 
            } >> $CONFIG_SIZE_FILE
        
        else
            echo "size analysis failed$CONFIG_NAME"
        fi
    else
        echo "size analysis already performed$CONFIG_NAME"
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

for config in "${CONFIG_LIST[@]}"; do
    load_config_env "$config"
    size_analysis
done
