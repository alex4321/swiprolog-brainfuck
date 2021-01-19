/* Memory implementation. It's a bit dirty */
get_memory_term(Address, Name) :- number_string(Address, AddressString), string_concat("memory_", AddressString, NameString), atom_string(Name, NameString).
set_memory(Address, Value) :- get_memory_term(Address, Name), b_setval(Name, Value).
get_memory(Address, Value) :- get_memory_term(Address, Name), nb_current(Name, Value).
get_memory(_, Value) :- Value=0.

list_size([], 0).
list_size([_|T], Size) :- list_size(T, TailSize), Size is TailSize + 1.

remove_first_elements(List, 0, List).
remove_first_elements([_|T], Remove, ResultList) :- NextRemove is Remove - 1, remove_first_elements(T, NextRemove, ResultList).

first_element([], []).
first_element([H|_], H).

/* Extract subsequence until correct ']' when '[' found */
extract_sequence(_, [], 0).
extract_sequence(['['|T], Result, Depth) :- NewDepth is Depth + 1, extract_sequence(T, TailResult, NewDepth), append(['['], TailResult, Result).
extract_sequence([']'|_], [], 1).
extract_sequence([']'|T], Result, Depth) :- NewDepth is Depth - 1, extract_sequence(T, TailResult, NewDepth), append([']'], TailResult, Result).
extract_sequence([Operator|T], Result, Depth) :- Depth>0, extract_sequence(T, TailResult, Depth), append([Operator], TailResult, Result).
extract_sequence([], [], _).

/* Parse program to list of instruction-parameter pairs, where possible instructions:
 * - next_cell, no params - '>'
 * - previous_cell, no params - '<'
 * - plus_cell, no params - '+'
 * - minus_cell, no params - '-'
 * - print_cell, no params - '.'
 * - input_cell, no params - ','
 * - while_loop, parsed subprogram (sequence after '[' until corresponding ']') - '[', until ']'
 * All other characters ignored 
 */
parse_sequence(['>'|T], Result) :- parse_sequence(T, TailResult), append([[next_cell, _]], TailResult, Result).
parse_sequence(['<'|T], Result) :- parse_sequence(T, TailResult), append([[previous_cell, _]], TailResult, Result).
parse_sequence(['+'|T], Result) :- parse_sequence(T, TailResult), append([[plus_cell, _]], TailResult, Result).
parse_sequence(['-'|T], Result) :- parse_sequence(T, TailResult), append([[minus_cell, _]], TailResult, Result).
parse_sequence(['.'|T], Result) :- parse_sequence(T, TailResult), append([[print_cell, _]], TailResult, Result).
parse_sequence([','|T], Result) :- parse_sequence(T, TailResult), append([[input_cell, _]], TailResult, Result).
parse_sequence(['['|T], Result) :- extract_sequence(T, SubSeq, 1), 
    parse_sequence(SubSeq, SubSeqParsed),
    list_size(SubSeq, SubSeqSize),
    remove_first_elements(T, SubSeqSize + 1, NextOperators),
    parse_sequence(NextOperators, TailResult),
    append([[while_loop, SubSeqParsed]], TailResult, Result).
parse_sequence([_|T], Result) :- parse_sequence(T, Result).
parse_sequence([], []).

/* Run one operator */
run_operator([next_cell|_], CellIndex, NewCellIndex) :- NewCellIndex is CellIndex + 1.
run_operator([previous_cell|_], CellIndex, NewCellIndex) :- NewCellIndex is CellIndex - 1.
run_operator([plus_cell|_], CellIndex, CellIndex) :- get_memory(CellIndex, Value), NewValue is Value + 1, set_memory(CellIndex, NewValue).
run_operator([minus_cell|_], CellIndex, CellIndex) :- get_memory(CellIndex, Value), NewValue is Value - 1, set_memory(CellIndex, NewValue).
run_operator([print_cell|_], CellIndex, CellIndex) :- get_memory(CellIndex, Value), char_code(Character, Value), write(Character).
run_operator([input_cell|_], CellIndex, CellIndex) :- get_char(Character), char_code(Character, Value), set_memory(CellIndex, Value).
run_operator([while_loop|SubProgramWrapped], CellIndex, NewCellIndex) :- get_memory(CellIndex, Value),
    not(Value = 0),
    first_element(SubProgramWrapped, SubProgram),
    run_programm(SubProgram, CellIndex, IntermediateCellIndex),
    append([while_loop], SubProgramWrapped, RerunOperator),
    run_operator(RerunOperator, IntermediateCellIndex, NewCellIndex).
run_operator([while_loop|_], CellIndex, NewCellIndex) :- get_memory(CellIndex, 0), 
    NewCellIndex is CellIndex.    

/* Run whole parsed program */
run_programm([OperatorWithParams|T], CellIndex, NewCellIndex) :- run_operator(OperatorWithParams, CellIndex, IntermediateCellIndex), run_programm(T, IntermediateCellIndex, NewCellIndex).
run_programm([], Cell, Cell).

?-current_prolog_flag(argv, [FileName]), /* Get file name from command line */
    read_file_to_string(FileName, Code, []),  /* Read code */
    string_chars(Code, CodeChars),
    parse_sequence(CodeChars, ParsedProgram), /* Parse code */
    /*Then run*/
    run_programm(ParsedProgram, 0, _),
    halt().