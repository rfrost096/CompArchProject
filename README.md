# Abstract
The large-scale use of highly repetitive algorithms in
fields such as machine learning and signal processing creates an
opportunity to improve efficiency with processor cores designed
for specific types of workloads rather than the traditional general
purpose processor core. This project addresses the systematic
categorization of applications based on execution needs and
connects those needs to specific processor configurations for
optimal performance. Using RISC-V instruction set architecture
and Verilator simulations, we will analyze a number of trial
configurations for each defined category of workloads, and we
will optimize one specific configuration for each category. The
effectiveness of these optimized configurations will be tested by
running both category-specific benchmarks and generic bench-
marks. This will show how optimizing for specific workloads will
improve efficiency for those categories over a generic core.