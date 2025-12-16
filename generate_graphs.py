
OUTPUT_DIR = "output/"
RESULTS_NAME = "results.txt"
WORKLOADS = ["aes", "dijkstra_boom"]

def parse_run_data(results_file: str):
    results: str = ""
    with open(results_file, 'r') as f:
        results = f.read()
    
    result_list = results.split('----')[:-1]
    
    workload_dict: dict[str, dict[str, int]] = {}
    
    for result in result_list:
        id_idx = result.find("ID: ")
        newline_idx = result[id_idx:].find("\n")
        
        id = result[id_idx+4:newline_idx+id_idx]
        
        data_idx = result.find("cycles")
        data_end_idx = result.find("L2 TLB miss")
        
        data = result[data_idx:data_end_idx]
        
        data_parts = data.split('\n')
        
        data_dict: dict[str, int] = {}
        
        for data_part in data_parts:
            if data_part.find(':') != -1:
                data_split = data_part.strip().split(" : ")
                data_dict[data_split[0]] = int(data_split[1])
        
        workload_dict[id] = data_dict
    
    return workload_dict

if __name__ == '__main__':
    for workload in WORKLOADS:
        workload_dict = parse_run_data(OUTPUT_DIR + workload + "/" + RESULTS_NAME)