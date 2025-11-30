package chipyard

import org.chipsalliance.cde.config.{Config}

import chisel3._
import chisel3.util.{log2Up}

import org.chipsalliance.cde.config.{Parameters, Config, Field}
import freechips.rocketchip.subsystem._
import freechips.rocketchip.devices.tilelink.{BootROMParams}
import freechips.rocketchip.prci.{SynchronousCrossing, AsynchronousCrossing, RationalCrossing}
import freechips.rocketchip.rocket._
import freechips.rocketchip.tile._

import boom.v3.ifu._
import boom.v3.exu._
import boom.v3.lsu._

import boom.v3.common._

/* 
Here are the seven configurable parameters we chose:
- cache size
- cache associativity
- pipeline architecture
- virtual memory
- floating point unit
- translation lookaside buffer
- branch predictor

Here is a mapping of that parameter to its variable name:
Cache variables:
- cache size -----------------------> cache_line_size
- cache associativity --------------> cache_associativity
- translation lookaside buffer -----> num_tlb_ways

Core variables:
- floating point unit --------------> frontend_width            <-- Changing from FPU to frontend width b/c not much to change in FPU other than removing it
- pipeline architecture ------------> super_scalar_width
- virtual memory -------------------> working_window_width      <-- Changing from virtual mem to working window, not much to change with virtual mem

Branch predictor:
- branch predictor -----------------> branch_predictor

Comments:
We may want to also change number of cache sets as part of the cache size parameter

FPU change: 
We can change the latency of the FPU, which isn't that interesting. We can change the
floating point accuracy from 64 (double) to 32, but that might break code expecting to
use double accuracy. We can remove it entirely, but floating point operations using
software emulation and integer operations is very very slow. Overall I think we should
not mess with FPU.

Virtual memory change:
Similar issue of not having a lot of parameters to change. We could possibly change the
virtual memory protocol (shown in comments below) but I don't think that is very
interesting. It is mostly for larger programs / when multiple programs are running.

Breakdown of core variables:
There are a number of pre configured BOOM cores (small, medium, large, mega, giga).
Each has changes to the BoomCoreParams. For this assignment, we need more granular
changes to the core (requiring seven parameters). To acheive this, I have divided the
core parameters into three groups to hopefully show how certain groups are more important
than others for the specific workloads we use.

Goal of the project:
Obviously, the larger cores are going to have higher performance. We could just
use the giga chip and say that is the fastest for all workloads. However, the goal is to
show how we can optimize chip parameters more granularly for specific tasks.
General chip analysis uses PPA (Power, Performance, Area). 
Performance can be measured in the same way we have done for the homeworks.
We can use metrics like Instructions per Cycle to show performance.
For area, we can use Hammer in the chipyard toolset to get a mm2 value for a specific config.
There seems to be two different ways of measuring power, static and dynamic.
I'm more inclined to look into dynamic for specific workloads, but it apparently is pretty slow.
Generally, power seems to be the more complicated measurment, which is unsurprising.
I'm going to focus on getting a performance vs area graph for a specific workload testing maybe
10 different configurations. We can go from there and maybe expand to measure power as well.
*/

class ModularBoomConfig extends Config(
    new WithModularBoom(
        sys.env.getOrElse("CACHE_LINE_SIZE_PARAM", "64").toInt,     // cache_line_size
        sys.env.getOrElse("CACHE_ASSOCIATIVITY_PARAM", "4").toInt,  // cache_associativity
        sys.env.getOrElse("NUM_TLB_WAYS_PARAM", "8").toInt,         // num_tlb_ways
        sys.env.getOrElse("FRONTEND_WIDTH_PARAM", "medium"),        // frontend_width
        sys.env.getOrElse("SUPER_SCALAR_WIDTH_PARAM", "medium"),    // super_scalar_width
        sys.env.getOrElse("WORKING_WINDOW_WIDTH_PARAM", "medium"),  // working_window_width
        sys.env.getOrElse("BRANCH_PREDICTOR_PARAM", "TAGELBPD"),    // branch_predictor
    ) ++
    new chipyard.config.AbstractConfig)

class WithModularBoom(cache_line_size: Int, cache_associativity: Int, num_tlb_ways: Int, frontend_width: String, super_scalar_width: String, working_window_width: String, branch_predictor: String) extends Config(

    /* There are 4 branch predictors defined in CompArchProject/chipyard/generators/boom/src/main/scala/v3/common/config-mixins.scala 
    
    These I assume are BOOM specific. There may be other branch predictors already configured that may work. */

    (branch_predictor match {
        case "TAGELBPD" => new WithTAGELBPD
        case "Boom2BPD" => new WithBoom2BPD
        case "Alpha21264BPD" => new WithAlpha21264BPD
        case "SWBPD" => new WithSWBPD
    }) ++

    new Config((site, here, up) => {
        case TilesLocated(InSubsystem) => {
            val prev = up(TilesLocated(InSubsystem), site)
            val idOffset = up(NumTiles)
            (0 until 1).map { i => // Removing # of cores as we are not changing that parameter

                // Adding this here b/c it is needed in instruction cache
                val fetch_width_int = frontend_width match {
                    case "small" => 4
                    case "medium" => 4
                    case "large" => 8
                    case "mega" => 8
                }

                BoomTileAttachParams(
                    tileParams = BoomTileParams(
                        core = BoomCoreParams(

                            // Frontend Width:
                            fetchWidth = fetch_width_int,

                            /* Comments on numFetchBufferEntries changes:

                            Lines 53-54 of CompArchProject/chipyard/generators/boom/src/main/scala/v3/ifu/fetch-buffer.scala
                            require (numEntries > fetchWidth)
                            require (numEntries % coreWidth == 0)

                            Since possible coreWidth (dispatchWidth) values are 1, 2, 3, 4, the 
                            numFetchBufferEntries must be divisble by 12. I have edited them
                            to fulfill this requirement.
                            */

                            numFetchBufferEntries = frontend_width match {
                                case "small" => 12      // Changing from 8 -> 12
                                case "medium" => 12     // Changing from 16 -> 12
                                case "large" => 24      // Keeping at 24
                                case "mega" => 36       // Changing from 32 -> 36
                            },

                            ftq = frontend_width match {
                                case "small" => FtqParameters(nEntries=16)
                                case "medium" => FtqParameters(nEntries=32)
                                case "large" => FtqParameters(nEntries=32)
                                case "mega" => FtqParameters(nEntries=40)
                            },

                            // Super Scalar Width:
                            // I did not initially have decodeWidth in the super scalar width because I view it as
                            // more of a frontend parameter, but there is a requirement where the dispatchWidth
                            // for any IssueParams must be less than or equal to the decodeWidth. Seeing as it is
                            // typically equal, I have just moved the decodeWidth to this section.
                            decodeWidth = super_scalar_width match {
                                case "small" => 1
                                case "medium" => 2
                                case "large" => 3
                                case "mega" => 4
                            },
                            issueParams = super_scalar_width match {
                                case "small" => Seq(
                                    IssueParams(issueWidth=1, numEntries=8, iqType=IQT_MEM.litValue, dispatchWidth=1),
                                    IssueParams(issueWidth=1, numEntries=8, iqType=IQT_INT.litValue, dispatchWidth=1),
                                    IssueParams(issueWidth=1, numEntries=8, iqType=IQT_FP.litValue , dispatchWidth=1))
                                case "medium" => Seq(
                                    IssueParams(issueWidth=1, numEntries=12, iqType=IQT_MEM.litValue, dispatchWidth=2),
                                    IssueParams(issueWidth=2, numEntries=20, iqType=IQT_INT.litValue, dispatchWidth=2),
                                    IssueParams(issueWidth=1, numEntries=16, iqType=IQT_FP.litValue , dispatchWidth=2))
                                case "large" => Seq(
                                    IssueParams(issueWidth=1, numEntries=16, iqType=IQT_MEM.litValue, dispatchWidth=3),
                                    IssueParams(issueWidth=3, numEntries=32, iqType=IQT_INT.litValue, dispatchWidth=3),
                                    IssueParams(issueWidth=1, numEntries=24, iqType=IQT_FP.litValue , dispatchWidth=3))
                                case "mega" => Seq(
                                    IssueParams(issueWidth=2, numEntries=24, iqType=IQT_MEM.litValue, dispatchWidth=4),
                                    IssueParams(issueWidth=4, numEntries=40, iqType=IQT_INT.litValue, dispatchWidth=4),
                                    IssueParams(issueWidth=2, numEntries=32, iqType=IQT_FP.litValue , dispatchWidth=4))
                            },

                            // Working Window Width:

                            /* Comments on ROB changes:

                            require (numRobEntries % coreWidth == 0) Line 288 in CompArchProject/chipyard/generators/boom/src/main/scala/v3/common/parameters.scala

                            There is a requirement in parameters.scala that numRobEntries % dispatchWidth == 0
                            Since there are 4 possible dispatch widths, the numRobEntries must be evenly divisible
                            by 1, 2, 3, 4. I changed the values to fullfill this requirement with the closest value.
                            */
                            numRobEntries = working_window_width match {
                                case "small" => 36      // Changing from 32 -> 36
                                case "medium" => 60     // Changing from 64 -> 60
                                case "large" => 96      // Keeping the same at 96
                                case "mega" => 132      // Changing from 128 -> 132
                            },
                            numIntPhysRegisters = working_window_width match {
                                case "small" => 52
                                case "medium" => 80
                                case "large" => 100
                                case "mega" => 128
                            },
                            numFpPhysRegisters = working_window_width match {
                                case "small" => 48
                                case "medium" => 64
                                case "large" => 96
                                case "mega" => 128
                            },
                            numLdqEntries = working_window_width match {
                                case "small" => 8
                                case "medium" => 16
                                case "large" => 24
                                case "mega" => 32
                            },
                            numStqEntries = working_window_width match {
                                case "small" => 8
                                case "medium" => 16
                                case "large" => 24
                                case "mega" => 32
                            },
                            maxBrCount = working_window_width match {
                                case "small" => 8
                                case "medium" => 12
                                case "large" => 16
                                case "mega" => 20
                            },

                            fpu = Some(freechips.rocketchip.tile.FPUParams(sfmaLatency=4, dfmaLatency=4, divSqrt=true)), // This is the same for all sizes

                            nPerfCounters = 29, // This allocates the counters we need for performance counters
                            enablePrefetching = true, // Keeping this in here for now, no particular reason

                            /* Found in CompArchProject/chipyard/generators/boom/src/main/scala/v3/common/parameters.scala 
                            line 93 */
                            useVM = true

                            /* Found in CompArchProject/chipyard/generators/boom/util/csmith/sources/encoding.h
                            lines 123-128 */
                            // #define SATP_MODE_OFF  0
                            // #define SATP_MODE_SV32 1
                            // #define SATP_MODE_SV39 8
                            // #define SATP_MODE_SV48 9
                            // #define SATP_MODE_SV57 10
                            // #define SATP_MODE_SV64 11

                            /* SATP stands for Supervisor Address Translation and Protection register 
                            OFF means no translation, virtual address is physical address
                            SV32 is 32-bit virtual address space, two-level page tables
                            SV39 is default, 39-bit virtual address apsce, three-level page tables
                            SV48 uses 48-bit virtual address space, four-level page tables
                            Sv57 uses 57-bit virtual address space, five-level page tabels */
                        ),
                        dcache = Some(
                            DCacheParams(
                                blockBytes=cache_line_size, // added dynamic cache_line_size
                                rowBits = (fetch_width_int/4)*64, 
                                nSets=64, 
                                nWays=cache_associativity, // added dynamic cache_associativity
                                nMSHRs=2, 
                                nTLBWays=num_tlb_ways  // added dynamic num_tlb_ways
                            )
                        ),
                        icache = Some(
                            ICacheParams(
                                rowBits = (fetch_width_int/4)*64, 
                                nSets=64, 
                                nWays=(fetch_width_int/4)*4, 
                                fetchBytes=(fetch_width_int/2)*4
                            )
                        ),
                        tileId = i + idOffset
                    ),
                    crossingParams = RocketCrossingParams()
                )
            } ++ prev
        }
        case NumTiles => up(NumTiles) + 1
    })
)