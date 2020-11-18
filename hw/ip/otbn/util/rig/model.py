# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

import random
from typing import Dict, List, Optional, Tuple

from shared.insn_yaml import Insn
from shared.operand import ImmOperandType, RegOperandType, OperandType

from .program import ProgInsn


class KnownMem:
    '''A representation of what memory/CSRs have architectural values'''
    def __init__(self, top_addr: int):
        assert top_addr > 0

        self.top_addr = top_addr
        # A list of pairs of addresses. If the pair (lo, hi) is in the list
        # then each byte in the address range {lo..hi - 1} has a known value.
        self.known_ranges = []  # type: List[Tuple[int, int]]

    def touch_range(self, base: int, width: int) -> None:
        '''Mark {base .. base+width} as known'''
        assert 0 <= width
        assert 0 <= base <= self.top_addr - width
        for off in range(width):
            self.touch_addr(base + off)

    def touch_addr(self, addr: int) -> None:
        '''Mark word starting at addr as known'''
        assert 0 <= addr < self.top_addr

        # Find the index of the last range that starts below us, if there is
        # one, and the index of the first range that starts above us, if there
        # is one.
        last_idx_below = None
        first_idx_above = None
        for idx, (lo, hi) in enumerate(self.known_ranges):
            if lo <= addr:
                last_idx_below = idx
                continue

            first_idx_above = idx
            break

        # Are we below all other ranges?
        if last_idx_below is None:
            # Are we one address below the next range above? In which case, we
            # need to shuffle it back one.
            if first_idx_above is not None:
                lo, hi = self.known_ranges[first_idx_above]
                assert addr < lo
                if addr == lo - 1:
                    self.known_ranges[first_idx_above] = (lo - 1, hi)
                    return

            # Otherwise, we're disjoint. Add a one-element range at the start.
            self.known_ranges = [(addr, addr + 1)] + self.known_ranges
            return

        # If not, are we inside a range? In that case, there's nothing to do.
        left_lo, left_hi = self.known_ranges[last_idx_below]
        if addr < left_hi:
            return

        left = self.known_ranges[:last_idx_below]

        # Are we just above it?
        if addr == left_hi:
            # If there is no range above, we can just extend the last range by one.
            if first_idx_above is None:
                self.known_ranges = left + [(left_lo, left_hi + 1)]
                return

            # Otherwise, does this new address glue two ranges together?
            assert first_idx_above == last_idx_below + 1
            right_lo, right_hi = self.known_ranges[first_idx_above]
            assert addr < right_lo

            if addr == right_lo - 1:
                self.known_ranges = (left + [(left_lo, right_hi)] +
                                     self.known_ranges[first_idx_above + 1:])
                return

            # Otherwise, we still extend the range by one (but have to put the
            # right hand list back too).
            self.known_ranges = (left + [(left_lo, left_hi + 1)] +
                                 self.known_ranges[first_idx_above:])
            return

        # We are miles above the left range. If there is no range above, we can
        # just append a new 1-element range.
        left_inc = self.known_ranges[:first_idx_above]
        if first_idx_above is None:
            self.known_ranges.append((addr, addr + 1))
            return

        # Otherwise, are we just below the next range?
        assert first_idx_above == last_idx_below + 1
        right_lo, right_hi = self.known_ranges[first_idx_above]
        assert addr < right_lo

        if addr == right_lo - 1:
            self.known_ranges = (left_inc + [(right_lo - 1, right_hi)] +
                                 self.known_ranges[first_idx_above + 1:])
            return

        # If not, we just insert a 1-element range in between
        self.known_ranges = (left_inc + [(addr, addr + 1)] +
                             self.known_ranges[first_idx_above:])
        return

    def pick_lsu_target(self,
                        loads_value: bool,
                        min_addr: int,
                        max_addr: int) -> Optional[int]:
        '''Try to pick a 4-byte aligned address in range [min_addr, max_addr]

        If loads_value is true, the memory needs a known value at that
        address.

        '''
        assert min_addr <= max_addr

        if min_addr >= self.top_addr or max_addr < 0:
            return None

        min_addr = max(0, min_addr)
        max_addr = min(max_addr, self.top_addr - 1)

        # We don't know that min_addr and max_addr are aligned. Move them "in"
        # if necessary to ensure that they are, dividing by 4 to turn them into
        # word addresses.
        min_word = (min_addr + 3) // 4
        max_word = max_addr // 4

        if max_word < min_word:
            return None

        if not loads_value:
            # If we're not loading something, we can pick any old address in
            # the range.
            return 4 * int(random.randrange(min_word, max_word + 1))

        # If we are loading something, we need to be more careful. Collect up
        # the known ranges that have an intersection with the range in
        # question, converting to word addresses as we go. Note that the (lo,
        # hi) pairs don't include the right endpoint, but min_word/max_word
        # does, so we need a +1 every so often.
        word_ranges = []
        weights = []
        for byte_lo, byte_hi in self.known_ranges:
            word_lo = max((byte_lo + 3) // 4, min_word)
            word_hi = min(byte_hi // 4, max_word + 1)
            if word_lo < word_hi:
                word_ranges.append((word_lo, word_hi))
                weights.append(word_hi - word_lo)

        # If there are no ranges that intersect, give up.
        if not word_ranges:
            return None

        # Otherwise, pick a range with weight equal to the number of elements
        # in the range (so we'll get a uniform sampling on valid addresses) and
        # then pick from the range.
        word_lo, word_hi = random.choices(word_ranges, weights=weights)[0]
        return 4 * random.randrange(word_lo, word_hi)


class Model:
    '''An abstract model of the processor and memories

    This definitely doesn't try to act as a simulator. Rather, it tracks what
    registers and locations in memory are guaranteed have defined values after
    following the instruction stream to this point.

    '''
    def __init__(self, dmem_size: int, reset_addr: int) -> None:
        self.dmem_size = dmem_size

        # Known values for registers. This is a dictionary mapping register
        # type to a dictionary of known registers of that type. The register
        # type is a string matching the formats in RegOperandType.TYPE_FMTS.
        # The value for a type is another dictionary, mapping register index to
        # an Optional[int]. If the value is a number, the register value is
        # known to currently equal that number. If it is None, the register
        # value is unknown (but the register does have an architectural value).
        #
        # Note that x1 behaves a bit strangely because of the call stack rules,
        # so we don't store it in _known_regs but instead in _call_stack.
        self._known_regs = {}  # type: Dict[str, Dict[int, Optional[int]]]

        # Set x0 (the zeros register)
        self._known_regs['gpr'] = {0: 0}

        # A call stack, representing the contents of x1. The top of the stack
        # is at the end (position -1), to match Python's list.pop function. A
        # entry of None means an entry with an architectural value, but where
        # we don't actually know what it is (usually a result of some
        # arithmetic operation that got written to x1).
        self._call_stack = []  # type: List[Optional[int]]

        # Known values for memory, keyed by memory type ('dmem', 'csr', 'wsr').
        self._known_mem = {
            'dmem': KnownMem(dmem_size),
            # TODO: How many CSRs/WSRs? Is that written down somewhere we can
            # extract?
            'csr': KnownMem(4096),
            'wsr': KnownMem(4096)
        }

        # The current PC (the address of the next instruction that needs
        # generating)
        self.pc = reset_addr

    def read_reg(self, reg_type: str, idx: int) -> None:
        '''Update the model for a read of the given register

        This is mostly ignored, but has an effect for x1, which pops from the
        call stack on a read.

        '''
        if reg_type == 'gpr' and idx == 1:
            assert self._call_stack
            self._call_stack.pop()

    def write_reg(self,
                  reg_type: str,
                  idx: int,
                  value: Optional[int],
                  update: bool) -> None:
        '''Mark a register as having an architectural value

        If value is not None, it is the actual value that the register has.
        Writes to the zeros register x0 are ignored.

        The update flag is normally False. If set, it means that other code has
        already updated the model with a write of a value to the register for
        this instruction, and we should replace that value with the given one,
        which refines the previous value. This is irrelevant for idempotent
        registers, but matters for x1.

        '''
        if reg_type == 'gpr':
            if idx == 0:
                # Ignore writes to x0
                return

            if idx == 1:
                # Special-case writes to x1
                if update:
                    assert self._call_stack
                    assert self._call_stack[-1] in [None, value]
                    self._call_stack[-1] = value
                else:
                    self._call_stack.append(value)
                return

        self._known_regs.setdefault(reg_type, {})[idx] = value

    def get_reg(self, reg_type: str, idx: int) -> Optional[int]:
        '''Get a register value, if known.'''
        if reg_type == 'gpr' and idx == 1:
            return self._call_stack[-1] if self._call_stack else None

        return self._known_regs.setdefault(reg_type, {}).get(idx)

    def touch_mem(self, mem_type: str, base: int, width: int) -> None:
        '''Mark {base .. base+width} as known for given memory type'''
        assert mem_type in self._known_mem
        self._known_mem[mem_type].touch_range(base, width)

    def pick_operand_value(self, op_type: OperandType) -> Optional[int]:
        '''Pick a random value for an operand

        The result will always be non-negative: if the operand is a signed
        immediate, this is encoded as 2s complement.

        '''
        if isinstance(op_type, RegOperandType):
            return self.pick_reg_operand_value(op_type)

        op_rng = op_type.get_op_val_range(self.pc)
        if op_rng is None:
            # If we don't know the width, the only immediate that we *know*
            # is going to be valid is 0.
            return 0

        if isinstance(op_type, ImmOperandType):
            shift = op_type.shift
        else:
            shift = 0

        align = 1 << shift

        lo, hi = op_rng
        sh_lo = (lo + align - 1) // align
        sh_hi = hi // align

        op_val = random.randint(sh_lo, sh_hi) << shift
        return op_type.op_val_to_enc_val(op_val, self.pc)

    def pick_reg_operand_value(self, op_type: RegOperandType) -> Optional[int]:
        '''Pick a random value for a register operand

        Returns None if there's no valid value possible.'''
        if op_type.is_src():
            # This operand needs an architectural value. Pick a register
            # from the indices in _known_regs[op_type.reg_type].
            known_regs = self._known_regs.get(op_type.reg_type)
            if not known_regs:
                return None

            known_list = list(known_regs)
            if op_type.reg_type == 'gpr':
                # Add x1 if to the list of known registers (if it has an
                # architectural value). This won't appear in known_regs,
                # because we don't track x1 there.
                assert 1 not in known_regs
                if self._call_stack:
                    known_list.append(1)

            return random.choice(known_list)

        # This operand isn't treated as a source. Pick any register!
        assert op_type.width is not None
        return random.getrandbits(op_type.width)

    def regs_with_known_vals(self, reg_type: str) -> List[Tuple[int, int]]:
        '''Find registers whose values are known

        Returns a list of pairs (idx, value) where idx is the register index
        and value is its value.

        '''
        ret = []
        known_regs = self._known_regs.setdefault(reg_type, {})
        for reg_idx, reg_val in known_regs.items():
            if reg_val is not None:
                ret.append((reg_idx, reg_val))

        # Handle x1, which has a known value iff the top of the call stack is
        # not None
        if reg_type == 'gpr':
            assert 1 not in known_regs
            if self._call_stack and self._call_stack[-1] is not None:
                ret.append((1, self._call_stack[-1]))

        return ret

    def pick_lsu_target(self,
                        mem_type: str,
                        loads_value: bool,
                        known_regs: Dict[str, List[Tuple[int, int]]],
                        imm_min: int,
                        imm_max: int,
                        byte_width: int) -> Optional[Tuple[int,
                                                           int,
                                                           Dict[str, int]]]:
        '''Try to pick an address for an LSU operation.

        mem_type is the type of memory (which must a key of self._known_mem).
        If loads_value, this address needs to have an architecturally defined
        value.

        known_regs is a map from operand name to a list of pairs (idx, value)
        with index and known value for this register operand. Any immediate
        operand will have a value in the range [imm_min, imm_max]. byte_width
        is the number of contiguous addresses that the LSU operation touches.

        Returns None if we can't find an address. Otherwise, returns a tuple
        (addr, imm_val, reg_vals) where addr is the target address, imm_val is
        the value of any immediate operand and reg_vals is a map from operand
        name to the index picked for that register operand.

        '''
        assert mem_type in self._known_mem
        assert imm_min <= imm_max

        # A "general" solution to this needs constraint solving, but we expect
        # [imm_min, imm_max] to cover most of the address space most of the
        # time. So we'll do something much simpler: pick a value for each
        # register, then pick a target address that can be reached from the
        # "sum so far" plus the range of the immediate.
        reg_indices = {}
        reg_sum = 0

        for name, indices in known_regs.items():
            # If there are no known indices for this operand, give up now.
            if not indices:
                return None

            # Otherwise, pick an index and value
            idx, value = random.choice(indices)
            reg_sum += value
            reg_indices[name] = idx

        # TODO: This is a bit pessimistic, because it doesn't allow things like
        #       the register sum coming to -1 (module 2^32) and adding an
        #       immediate 1 to get a valid address.
        min_addr = reg_sum + imm_min
        max_addr = reg_sum + imm_max
        known_mem = self._known_mem[mem_type]

        addr = known_mem.pick_lsu_target(loads_value, min_addr, max_addr)

        # If there was no address we could use, give up.
        if addr is None:
            return None

        return (addr, addr - reg_sum, reg_indices)

    def update_for_lui(self, insn: Insn, op_vals: List[int]) -> None:
        '''Update model state after a LUI

        A lui instruction looks like "lui x2, 80000" or similar. This operation
        is easy to understand, so we can actually update the model registers
        appropriately.

        '''
        assert insn.mnemonic == 'lui'
        assert len(insn.operands) == len(op_vals)

        exp_shape = (len(insn.operands) == 2 and
                     isinstance(insn.operands[0].op_type, RegOperandType) and
                     insn.operands[0].op_type.reg_type == 'gpr' and
                     insn.operands[0].op_type.is_dest() and
                     isinstance(insn.operands[1].op_type, ImmOperandType) and
                     not insn.operands[1].op_type.signed)
        if not exp_shape:
            raise RuntimeError('LUI instruction read from insns.yml is '
                               'not the shape expected by '
                               'Model.update_for_lui.')

        assert op_vals[1] >= 0
        self.write_reg('gpr', op_vals[0], op_vals[1], True)

    def update_for_addi(self, insn: Insn, op_vals: List[int]) -> None:
        '''Update model state after an ADDI

        If the source register happens to have a known value, we can do the
        addition and store the known result.

        '''
        assert insn.mnemonic == 'addi'
        assert len(insn.operands) == len(op_vals)

        exp_shape = (len(insn.operands) == 3 and
                     isinstance(insn.operands[0].op_type, RegOperandType) and
                     insn.operands[0].op_type.reg_type == 'gpr' and
                     insn.operands[0].op_type.is_dest() and
                     isinstance(insn.operands[1].op_type, RegOperandType) and
                     insn.operands[1].op_type.reg_type == 'gpr' and
                     not insn.operands[1].op_type.is_dest() and
                     isinstance(insn.operands[2].op_type, ImmOperandType) and
                     insn.operands[2].op_type.signed)
        if not exp_shape:
            raise RuntimeError('ADDI instruction read from insns.yml is '
                               'not the shape expected by '
                               'Model.update_for_addi.')

        src_val = self.get_reg('gpr', op_vals[1])
        if src_val is None:
            return

        value = src_val + op_vals[2]
        if value < 0:
            value += 1 << 32
            assert value >= 0
        if value >> 32:
            value -= 1 << 32
            assert (value >> 32) == 0

        self.write_reg('gpr', op_vals[0], value, True)

    def update_for_insn(self, prog_insn: ProgInsn) -> None:
        # Apply side-effecting reads (relevant for x1) then mark any
        # destination operand as having an architectural value
        insn = prog_insn.insn
        assert len(insn.operands) == len(prog_insn.operands)
        pending_writes = []  # type: List[Tuple[str, int]]
        for operand, op_val in zip(insn.operands, prog_insn.operands):
            op_type = operand.op_type
            if isinstance(op_type, RegOperandType):
                if op_type.is_dest:
                    pending_writes.append((op_type.reg_type, op_val))
                else:
                    self.read_reg(op_type.reg_type, op_val)
        for reg_type, op_val in pending_writes:
            self.write_reg(reg_type, op_val, None, False)

        # If this is a sufficiently simple operation that we understand the
        # result, actually set the destination register with a value.
        # Currently, we just support lui and addi
        if insn.mnemonic == 'lui':
            self.update_for_lui(insn, prog_insn.operands)
        elif insn.mnemonic == 'addi':
            self.update_for_addi(insn, prog_insn.operands)

        # If this is an LSU operation, we've either loaded a value (in which
        # case, the memory hopefully had a value already) or we've stored
        # something. In either case, we mark the memory as having a value now.
        if prog_insn.lsu_info is not None:
            assert insn.lsu is not None
            mem_type, addr = prog_insn.lsu_info
            self.touch_mem(mem_type, addr, insn.lsu.idx_width)
