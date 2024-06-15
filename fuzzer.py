import sys
sys.path.append('/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Resources/Python3')
import lldb
import os
import random

def get_hit_count(target):
    count = 0
    for b in target.breakpoint_iter():
        count += b.GetHitCount()
    return count

def compute_coverage(target, coverage):
    current_coverage = []
    for i in range(target.num_breakpoints):
        b = target.GetBreakpointAtIndex(i)
        current_coverage.append("Breakpoint: {index} ;  Hit Count: {count}".format(index = i, count = b.GetHitCount()))
    if current_coverage not in coverage:
        coverage.append(current_coverage)

def print_coverage(coverage):
    print("Global coverage: \n")
    for subset in coverage:
        for line in subset:
            print(line)
        print("\n")


def generate_lower():
    input1 = random.randint(-sys.maxsize+1, sys.maxsize)
    input2 = random.randint(-sys.maxsize, input1)

    return [str(input1), str(input2)]


def generate_greater():
    input1 = random.randint(-sys.maxsize, sys.maxsize-1)
    input2 = random.randint(input1, sys.maxsize)

    return [str(input1), str(input2)]

def generate_equal():
    input1 = random.randint(-sys.maxsize, sys.maxsize)

    return [str(input1), str(input1)]

def mutate():
    mutators = [generate_lower, generate_greater, generate_equal]
    mutator = random.choice(mutators)
    return mutator()

def add_breakpoints(target):
    module = target.module[target.executable.basename]
    for symbol in module.symbols:
        if "dyld" not in str(symbol.GetStartAddress()) \
        and "_mh_execute_header" not in str(symbol.GetStartAddress()) \
        and "No value" not in str(symbol.GetStartAddress()) \
        and "unnamed" not in str(symbol.GetStartAddress()):
            target.BreakpointCreateBySBAddress(symbol.GetStartAddress())
        if "main" in str(symbol.GetStartAddress()):
            instr = symbol.GetInstructions(target)
            i = 0
            for instruction in instr:
                if 'cmpl' in instruction.GetMnemonic(target):
                    next_instr = instr.GetInstructionAtIndex(i + 2)
                    target.BreakpointCreateBySBAddress(next_instr.GetAddress())
                i += 1

def fuzz(debugger, raw_args, result, internal_dict):
    target = debugger.GetSelectedTarget()

    global coverage
    coverage = []
    data = []
    for i in range(30):
        data = mutate()
        print(data)
        add_breakpoints(target)
        process = target.LaunchSimple(data, None, os.getcwd())
        process.Continue()
        state = process.GetState()
        if state == lldb.eStateStopped:
            print("yayyyy")
        compute_coverage(target, coverage)
        print_coverage(coverage)
        process.Kill()
        target.DeleteAllBreakpoints()
    

def __lldb_init_module (debugger, dict):
    debugger.SetAsync(False)
    debugger.HandleCommand('command script add -f fuzzer.fuzz fuzz')

    print('The "fuzz" command has been loaded and is ready for use.')
