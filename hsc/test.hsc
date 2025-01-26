(global "boolean" first_global false)
(global "boolean" second_global false)
(global "short" iteration_counter 0)

(script continuous test_running_continously
    (print "[CONTINUOUS] Test running continously")
    (print "[CONTINUOUS] 1.- Sleeping 30 ticks")
    (sleep 30)
    (print "[CONTINUOUS] 2.- Now I'm awake")
    (set iteration_counter (+ iteration_counter 1))
    (if (= iteration_counter 3)
        (begin
            (print "[CONTINUOUS] 3.- Iteration counter reached 3")
            (set first_global true)
            (set second_global true)
            (print "[CONTINUOUS] 4.- Sleeping indefinitely")
            (sleep -1)
        )
    )
)

(script static "boolean" test_return_from_function
    (print "3.- Looking game difficulty after sleeping 90 ticks")
    (sleep 90)
    (print "4.- Now I'm awake")
    ; I'm just a comment
    ; (= normal (game_difficulty_get))
    (= (game_difficulty_get) normal)
)

(script static "void" test_call_and_sleep
    (print "1.- Test started")
    (sleep 30)
    (print "2.- Sleep finished")
    (if (test_return_from_function)
        (print "Game difficulty is normal")
        (print "Game difficulty is NOT normal")
    )
    (print "Sleeping until first_global or second_global are true")
    (sleep_until (or first_global second_global))
)

(script static "void" dummy_function
    (print "Dummy function")
)

(script static "void" test_begin_blocks
    (if (= hard (game_difficulty_get))
        (begin
            (dummy_function)
            (sleep 30)
            (dummy_function)
        )
        (begin
            ; Test proper string values handling
            (ai_place airlock_1_anti/boarding)
            (ai_place airlock_2_anti/boarding)
        )
    )
)

(script startup main
    (test_call_and_sleep)
    (sleep 30)
    (print "5.- Test done")
)