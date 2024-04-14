# SPDX-FileCopyrightText: © 2024 Clive Chan
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.triggers import Timer
from cocotb.binary import BinaryValue
from model import get_8bit_op, to_binary, to_float


@cocotb.test()
async def test_all_inputs(dut):
    """Test all possible pairs of 8-bit inputs."""

    fp8_mul_model = get_8bit_op(lambda a, b: a * b)

    # TODO: Test in random order
    for i in range(256):
        for j in range(256):
            dut.ui_in.value = BinaryValue(to_binary(i))
            dut.uio_in.value = BinaryValue(to_binary(j))
            await Timer(1, units="ms")
            correct = fp8_mul_model(i, j)
            assert dut.uo_out.value.binstr == f"{correct:08b}", f"{to_float(i)} ({i:08b}) * {to_float(j)} ({j:08b}) = {to_float(dut.uo_out.value.integer)} ({dut.uo_out.value.integer:08b}), should be {to_float(correct)} ({correct:08b})"
