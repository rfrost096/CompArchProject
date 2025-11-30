#ifndef _RISCV_HPM_H
#define _RISCV_HPM_H

/* Copied from Lab 1 */

/* The HPM_EVENT definitions for -->>BOOM<<-- can be found in CompArchProject/chipyard/generators/boom/src/main/scala/v3/exu/core.scala */
/* The hpmcounter definitions for -->>BOOM<<-- can be found in CompArchProject/chipyard/generators/boom/util/csmith/sources/encoding.h */

/* Comments on counters:

From looking at the definition in CompArchProject/chipyard/generators/boom/src/main/scala/v3/exu/core.scala (pasted down below),
it looks like the HPM_EVENT values should correctly line up, but I have not been able to verify it other that it looks
somewhat correct. Since we really should focus on cycles and instret for CPI, I don't think it is very critical atm to verify.
*/

#include <stdint.h>
#include <inttypes.h>
#include <stdio.h>

#ifdef __riscv

#define csr_read(reg) ({ \
    unsigned long __tmp; \
    __asm__ __volatile__ ("csrr %0, " #reg : "=r"(__tmp)); \
    __tmp; })

#define csr_write(reg, val) ({ \
    __asm__ __volatile__ ("csrw " #reg ", %0" :: "rK"(val)); })


#define HPM_NCOUNTERS           12

#define HPM_EVENTSET_BITS       8
#define HPM_EVENTSET_MASK       ((1U << HPM_EVENTSET_BITS) - 1)
#define HPM_EVENT(event, set)   ((1U << ((event) + HPM_EVENTSET_BITS)) | ((set) & HPM_EVENTSET_MASK))

struct hpm {
    uint64_t data[HPM_NCOUNTERS];
};

static inline void hpm_read(struct hpm *hpm)
{
    // #define CSR_CYCLE 0xc00 Line 754 in CompArchProject/chipyard/generators/boom/util/csmith/sources/encoding.h
    // DECLARE_CSR(cycle, CSR_CYCLE) Line 1246 in CompArchProject/chipyard/generators/boom/util/csmith/sources/encoding.h
    hpm->data[0] = csr_read(cycle);

    // #define CSR_INSTRET 0xc02 Line 756 in CompArchProject/chipyard/generators/boom/util/csmith/sources/encoding.h
    // DECLARE_CSR(instret, CSR_INSTRET) Line 1248 in CompArchProject/chipyard/generators/boom/util/csmith/sources/encoding.h
    hpm->data[1] = csr_read(instret);

    // hpmcounter is also defined in CompArchProject/chipyard/generators/boom/util/csmith/sources/encoding.h
    hpm->data[2] = csr_read(hpmcounter3);
    hpm->data[3] = csr_read(hpmcounter4);
    hpm->data[4] = csr_read(hpmcounter5);
    hpm->data[5] = csr_read(hpmcounter6);
    hpm->data[6] = csr_read(hpmcounter7);
    hpm->data[7] = csr_read(hpmcounter8);
    hpm->data[8] = csr_read(hpmcounter9);
    hpm->data[9] = csr_read(hpmcounter10);
    hpm->data[10] = csr_read(hpmcounter11);
    hpm->data[11] = csr_read(hpmcounter12);
}

static struct hpm hpm_data0;

/* Lines 247-271 of CompArchProject/chipyard/generators/boom/src/main/scala/v3/exu/core.scala

    val perfEvents = new freechips.rocketchip.rocket.EventSets(Seq(
    new freechips.rocketchip.rocket.EventSet((mask, hits) => (mask & hits).orR, Seq(
      ("exception", () => rob.io.com_xcpt.valid),
      ("nop",       () => false.B),
      ("nop",       () => false.B),
      ("nop",       () => false.B))),

    new freechips.rocketchip.rocket.EventSet((mask, hits) => (mask & hits).orR, Seq(
//      ("I$ blocked",                        () => icache_blocked),
      ("nop",                               () => false.B),
      ("branch misprediction",              () => b2.mispredict),
      ("control-flow target misprediction", () => b2.mispredict &&
                                                  b2.cfi_type === CFI_JALR),
      ("flush",                             () => rob.io.flush.valid),
      ("branch resolved",                   () => b2.valid)
    )),

    new freechips.rocketchip.rocket.EventSet((mask, hits) => (mask & hits).orR, Seq(
      ("I$ miss",     () => io.ifu.perf.acquire),
      ("D$ miss",     () => io.lsu.perf.acquire),
      ("D$ release",  () => io.lsu.perf.release),
      ("ITLB miss",   () => io.ifu.perf.tlbMiss),
      ("DTLB miss",   () => io.lsu.perf.tlbMiss),
      ("L2 TLB miss", () => io.ptw.perf.l2miss)))))
  val csr = Module(new freechips.rocketchip.rocket.CSRFile(perfEvents, boomParams.customCSRs.decls))        
*/

/* Initialize Rocket hardware performance monitor */
static inline void hpm_init(void)
{
    csr_write(mhpmevent3,  HPM_EVENT(1, 1)); // branch misprediction
    csr_write(mhpmevent4,  HPM_EVENT(2, 1)); // control-flow target misprediction
    csr_write(mhpmevent5,  HPM_EVENT(3, 1)); // flush 
    csr_write(mhpmevent6,  HPM_EVENT(4, 1)); // branch resolved

    csr_write(mhpmevent7,  HPM_EVENT(0, 2)); // I$ miss
    csr_write(mhpmevent8,  HPM_EVENT(1, 2)); // D$ miss
    csr_write(mhpmevent9,  HPM_EVENT(2, 2)); // D$ release
    csr_write(mhpmevent10,  HPM_EVENT(3, 2)); // ITLB miss
    csr_write(mhpmevent11,  HPM_EVENT(4, 2)); // DTLB miss
    csr_write(mhpmevent12,  HPM_EVENT(5, 2)); // L2 TLB miss

    hpm_read(&hpm_data0);
}

/* Dump performance counter data */
static inline void hpm_print(void)
{
    static const char *label[] = {
        "cycles",
        "instret",
        "branch misprediction",
        "control-flow target misprediction",
        "flush",
        "branch resolved",
        "I$ miss",
        "D$ miss",
        "D$ release",
        "ITLB miss",
        "DTLB miss",
        "L2 TLB miss",
    };
    _Static_assert((sizeof(label) / sizeof(char *)) == HPM_NCOUNTERS);
    struct hpm hpm_data1;
    char buf[HPM_NCOUNTERS*32];
    char *bufp;
    int i;

    hpm_read(&hpm_data1);
    for (i = 0, bufp = buf; i < HPM_NCOUNTERS; i++) {
        int n;
        n = sprintf(bufp, "%18s : %" PRIu64 "\n", label[i], hpm_data1.data[i] - hpm_data0.data[i]);
        if (n < 0)
            break;
        bufp += n;
    }
    fputs(buf, stdout);
}

#else /* !__riscv */

static inline void hpm_init()
{
}

static inline void hpm_print()
{
}

#endif /* __riscv */

#endif /* _RISCV_HPM_H */
