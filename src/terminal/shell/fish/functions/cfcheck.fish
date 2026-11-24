function cfcheck --description 'Compile cp/template.cpp and run it against cp/tests.txt (run from forge root)'
    g++ cp/template.cpp -g -o cp/a.out
    and python3 cp/run_tests.py cp/tests.txt cp/a.out
end
