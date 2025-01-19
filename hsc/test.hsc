(global "boolean" first_global false)
(global "boolean" second_global false)

(script continuous test_running_continously
    (print "6.- Running continously")
    (sleep 30)
    (print "7.- Continous test done")
)

(script static "boolean" test_return_from_function
    (print "3.- Looking game difficulty after sleeping 30 ticks")
    (sleep 30)
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
    )
    (sleep_until first_global)
    (sleep_until (or second_global (and (!= (game_difficulty_get) normal) first_global)))
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

(script static "void" main
    (test_call_and_sleep)
    (sleep 30)
    (print "5.- Test done")
)