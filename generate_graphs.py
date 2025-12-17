
OUTPUT_DIR = "output/"
RESULTS_NAME = "results.txt"
WORKLOADS = ["aes", "dijkstra_boom"]
CONFIG_SIZE_FILE = "output/config/config_sizes.txt"

def parse_id(content: str):
    id_idx = content.find("ID: ")
    newline_idx = content[id_idx:].find("\n")
    
    id = content[id_idx+4:newline_idx+id_idx]
    
    return id

def parse_size_data(config_size_file: str):
    sizes: str = ""
    
    with open(config_size_file, 'r') as f:
        sizes = f.read()
    
    size_list = sizes.split('\n----\n')[:-1]
    
    size_dict: dict[str, int] = {}
    
    for size in size_list:
        
        id = parse_id(size)
        
        top_idx = size.find("DigitalTop")
        
        line_idx = size[:top_idx].rfind("\n")
        size_val = 1
        try:
            size_val = int(float(size[line_idx:top_idx].strip()))
        except:
            print("errr")
        
        size_dict[id] = size_val
    
    return size_dict
    
    

def parse_run_data(results_file: str):
    results: str = ""
    with open(results_file, 'r') as f:
        results = f.read()
    
    result_list = results.split('----')[:-1]
    
    workload_dict: dict[str, dict[str, int]] = {}
    
    for result in result_list:
        id = parse_id(result)
        
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
    
    size_dict = parse_size_data(CONFIG_SIZE_FILE)
    
    for workload in WORKLOADS:
        workload_dict = parse_run_data(OUTPUT_DIR + workload + "/" + RESULTS_NAME)