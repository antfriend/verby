{{
         "hypnoray"
        a meditator

       ,aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
      d'                                                                    8
    ,P'                                                                     8
  ,dbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa        8
  8                                                              d"8        8
  8                                                             d' 8        8
  8        aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaad'  8        8
  8        8   8                                               8   8        8
  8        8   8                                               8   8        8
  8        8  ,8aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa8aaa8        8
  8        8 ,P                                                             8
  8        8,P                                                              8
  8        8baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaad'
  8                                                                       d'
  8                                                                      d'
  8aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaP'
                       (ascii art by Normand Veilleux)
                       
}}

CON
  _xinfreq = 5_000_000
  _clkmode = xtal1 + pll16x

  'timing
  ONE_QUARTER_SECOND = 20_000_000

  'pins
  led_pin = 10
  status_pin = 11
  heart_pin = 3
  smooth_operator = 3 'the max index

  INPUT         = false         'bit pattern is all 0s
  OUTPUT        = true          'bit pattern is all 1s
  
  'LED Bar graph pin definitions
  BAR_GRAPH_0   = 0
  BAR_GRAPH_1   = 1
  BAR_GRAPH_2   = 2
  BAR_GRAPH_3   = 3
  BAR_GRAPH_4   = 4
  BAR_GRAPH_5   = 5
  BAR_GRAPH_6   = 6
  BAR_GRAPH_7   = 7
  BAR_GRAPH_8   = 8
  BAR_GRAPH_9   = 9

  Direction_Magic_Number = 3
  
'Verbalizers ******************* ********* *******************
'*** Key States ***
     'greater than 3 is the count within the debounce range 
        'DEBOUNCE= 100_000
        TRIGGER = 3
        SUSTAIN = 2
        RELEASE = 1
        SILENCE = 0
'*** mode *****************************************************
        DO_NOTHING = 0
        PLAY_PHONEMES = 1 
        RECORD_PHONEMES = 2
        PLAY_ALLOPHONES = 3
        RECORD_ALLOPHONES = 4
        PLAY_WORDS = 5
        RECORD_WORDS = 6
        MODE_S1 = 27
        MODE_S2 = 28

                  
VAR
  Long is_reset
  Long smoothness[smooth_operator + 1] 'for 0 to smooth_operator indexing
  Long smooth_operator_iterator

  Long pressure
  Long cogStack[20]
  Long Direction_Breathing_in
  Long Direction_Previous_in
  Long Direction_Previous_reading
  Long Direction_Progress_Count
  Long Direction_Bar_Level
  Long Direction_Bar_Level_at_Release
  
  'Verbalizers *********************************************** 
  LONG Key_State[40]'each of 37 keys' Key States(TRIGGER, SUSTAIN, RELEASE, or SILENCE), but for iterating cols x rows I use 40
  BYTE The_Mode
  LONG ADC_Stack[20]'stack space allotment
  LONG Settings_Stack[20]'stack space allotment   
  BYTE Param[19]
  BYTE serial_progress
  LONG serial_started
  'using it
  LONG Keys_pressed_status

  'timing
  LONG main_loops_count
  LONG quarter_second_increments
  LONG cnt_to_quarter_second
        
OBJ
  system : "Propeller Board of Education"
  'pst    : "Parallax Serial Terminal Plus"
  time   : "Timing"
  adc    : "PropBOE ADC"
  
  Verbalizations   :   "theVerbalizer"
          
PRI init | i, the_key

  'system variables, don't touch
  system.Clock(80_000_000)
  is_reset := TRUE
  
  dira[led_pin] := 1
  dira[status_pin] := 1
  dira[heart_pin] := 0
  outa[heart_pin] := 1

  dira[BAR_GRAPH_9..BAR_GRAPH_0] := OUTPUT
  
  'initialize the smoothing array
  repeat i from 0 to smooth_operator
    smoothness[i] := adc.In(0)

  Set_Verbalizer_params
  The_Mode := PLAY_ALLOPHONES
  'The_Mode := PLAY_WORDS
  'The_Mode := PLAY_ALLOPHONES'phones
  'The_Mode := PLAY_PHONEMES
  Keys_pressed_status := FALSE
  repeat the_key from 0 to 38
    Key_State[the_key] := SILENCE
    
   'settings.start       
  Verbalizations.start(@Param)
  
  'timing
  main_loops_count := 0
  quarter_second_increments := 0
  cnt_to_quarter_second := cnt
  'test_the_timer
  'cosmic_orchestral_beat

PRI Quart_Second_Increment_Updater

  if cnt > ONE_QUARTER_SECOND + cnt_to_quarter_second
    
    cnt_to_quarter_second := cnt
    quarter_second_increments++

PRI test_the_timer

  repeat 4
    
    status_on
    
    repeat until quarter_second_increments > 3
     
      Quart_Second_Increment_Updater

    quarter_second_increments := 0  
    status_off
    
    repeat until quarter_second_increments > 3
     
      Quart_Second_Increment_Updater
    quarter_second_increments := 0

           
PRI Set_Verbalizer_params
  
  Param[0] := 16
  Param[1] := 255
  Param[2] := 10'64   volume
  
  Param[3] := 47
  Param[4] := 122
  Param[5] := 25
  Param[6] := 88
  Param[7] := 12'10    volume
  
  Param[8] := 4      'vibrato pitch  1/48 octave (12 notes to an octave) 4=1 note step
  Param[9] := 131'57 '110  'vibrato rate    : (5 / 0.0763 Hz) * 2 = 131
  Param[10] := 61
  Param[11] := 254    'release duration
  Param[12] := 230'echo     'from 180
  Param[13] := 2'2     volume
  
  Param[14] := 136
  Param[15] := 51
  Param[16] := 7
  Param[17] := 6
  Param[18] := 4
  'Param[19] := 0

PRI Verbalizer_Loop | the_key

        '******************************************************************
        Update_Keys
        
        case The_Mode
                                                
          PLAY_PHONEMES :
                                 repeat the_key from 1 to 37         
                                     if (Key_State[the_key] == RELEASE)'caught a release
                                         if Verbalizations.release_test(the_key)'if this one is stopping, then advance to SILENCE  
                                             Key_State[the_key] := SILENCE  'advance to silence
                                                      
                                 repeat the_key from 1 to 37                      
                                     if ((Key_State[the_key] == TRIGGER) OR (Key_State[the_key] == SUSTAIN))'caught a trigger
                                         if Verbalizations.go_test(the_key)
                                                        Key_State[the_key] := SUSTAIN
                                                   
          
          PLAY_ALLOPHONES : 'PLAY_ALLOPHONES = 3                      
                                repeat the_key from 1 to 37         
                                     if (Key_State[the_key] == RELEASE)'caught a release
                                         if Verbalizations.stop_if_available(the_key)'if this one is stopping, then advance to SILENCE  
                                             Key_State[the_key] := SILENCE  'advance to silence
                                 
                                repeat the_key from 1 to 37
                                     if (Key_State[the_key] == SUSTAIN)
                                        Verbalizations.go_sustain(the_key)
                                        
                                repeat the_key from 1 to 37       
                                     if (Key_State[the_key] == TRIGGER)'caught a trigger                 
                                         if Verbalizations.go_if_available(the_key)'if this one starts a voice, then advance to SUSTAIN
                                             Key_State[the_key] := SUSTAIN  'advance to sustain

          PLAY_WORDS : 'PLAY_WORDS
                                repeat the_key from 1 to 37         
                                     if (Key_State[the_key] == RELEASE)'caught a release
                                         if Verbalizations.release_word(the_key)'if this one is stopping, then advance to SILENCE  
                                             Key_State[the_key] := SILENCE  'advance to silence
                                 
                                repeat the_key from 1 to 37
                                     if (Key_State[the_key] == SUSTAIN)
                                        Verbalizations.sustain_word(the_key)
                                        
                                repeat the_key from 1 to 37       
                                     if (Key_State[the_key] == TRIGGER)'caught a trigger                 
                                         if Verbalizations.trigger_word(the_key)'if this one starts a voice, then advance to SUSTAIN
                                             Key_State[the_key] := SUSTAIN  'advance to sustain

                                             
          RECORD_WORDS : 'RECORD_WORDS = 4
                                 repeat the_key from 1 to 37                      
                                     if (Key_State[the_key] == TRIGGER)'caught a trigger
                                         Verbalizations.go_test(the_key)
          OTHER :
             'do nothing
             Verbalizations.release_test(1)
                                             
'*****END MAIN LOOP*************************************************************************************************************         
   
PRI Direction_Update
  ' Direction_Previous_reading

  if pressure == Direction_Previous_reading
    return

  if pressure > Direction_Previous_reading
    Direction_Breathing_in := TRUE
    
  if pressure < Direction_Previous_reading
    Direction_Breathing_in := FALSE

  'check if we are continuing in the same direction as last time
  if Direction_Breathing_in == Direction_Previous_in
  
    if Direction_Increment_Progress_t 'if Direction_Magic_Number threshold is met 
      if Direction_Breathing_in 'are we breathing in or breathing out?
      
        breathing_in
        
      else
      
        breathing_out
        
  else
    Direction_Decrement_Progress
    
  Direction_Previous_reading := pressure
  Direction_Previous_in := Direction_Breathing_in

PRI Keys_Pressed
  Keys_pressed_status := TRUE  
  'Update_Keys
  
PRI Keys_Released
  Keys_pressed_status := FALSE  
  'Update_Keys
  
PRI Update_Keys
  'Direction_Bar_Level =
'  if Keys_pressed_status
'    Update_this_Keys_State(Direction_Bar_Level, TRUE)
'    Update_this_Keys_State(Direction_Bar_Level+13, TRUE)
'    Update_this_Keys_State(Direction_Bar_Level+25, TRUE)     
'  else
'    Update_this_Keys_State(Direction_Bar_Level+1, FALSE)
'    Update_this_Keys_State(Direction_Bar_Level+13, FALSE)
'    Update_this_Keys_State(Direction_Bar_Level+25, FALSE)
    
  if Keys_pressed_status
    Update_this_Keys_State(1, TRUE)
    Update_this_Keys_State(13, TRUE)
    Update_this_Keys_State(25, TRUE)     
  else
    Update_this_Keys_State(1, FALSE)
    Update_this_Keys_State(13, FALSE)
    Update_this_Keys_State(25, FALSE)            

PRI Update_this_Keys_State(the_key, is_pressed) | the_count_now

  if (is_pressed == TRUE)
    if (Key_State[the_key] <> SUSTAIN)
       set_params_to_bar(Direction_Bar_Level)'###################################################
       Direction_Bar_Level_at_Release := Direction_Bar_Level
       Key_State[the_key] := TRIGGER
       
  else
    if (Key_State[the_key] == SUSTAIN)
       Key_State[the_key] := RELEASE
    else
       Key_State[the_key] := SILENCE 

PRI Direction_Decrement_Progress

  Direction_Progress_Count := Direction_Progress_Count - 1
  
  if Direction_Progress_Count < 0
    Direction_Progress_Count := 0

PRI Direction_Increment_Progress_t
  Direction_Progress_Count := Direction_Progress_Count + 1
  
  if Direction_Progress_Count > Direction_Magic_Number
    Direction_Progress_Count := Direction_Magic_Number
    
    return TRUE
  else
    return FALSE
        
PRI breathing_in
  Direction_Bar_Level := Direction_Bar_Level + 1
  
  if Direction_Bar_Level > 10
    Direction_Bar_Level := 10
  Set_the_bar(Direction_Bar_Level)
    
  'Update_this_Keys_State(the_key, is_pressed)
  
  'set the verbal release duration to match the breath duration
  
  Keys_Released
  

PRI breathing_out
  Direction_Bar_Level := Direction_Bar_Level - 1
  
  if Direction_Bar_Level < 1
    Direction_Bar_Level := 1
  Set_the_bar(Direction_Bar_Level)

  'set_params_to_bar(Direction_Bar_Level)

  main_loops_count := 0
  
  'set the pace of vibrato to match the level

  Keys_Pressed
  
PRI set_params_to_bar(bar_level)
  Param[2] := bar_level * 3  'volume
  Param[7] := (bar_level-1) * 3  'volume

  'Param[8] := bar_level / 2 'vibrato pitch
  'Param[9] := bar_level * 17 'vibrato rate

PRI Set_the_bar(theLevel)
  'set LED bar to equal Direction_Bar_Level
   outa[BAR_GRAPH_9..BAR_GRAPH_0] := 1<<theLevel-1   
  
PRI cosmic_orchestral_beat | timer
  {
  blinkity blink blinker
  }
    timer := 100
     
    repeat 4
      status_on
      led_off
      time.Pause(timer)
      status_off
      led_on
      Keys_Pressed
      Verbalizer_Loop
      time.Pause(timer*2)
      Verbalizer_Loop
      time.Pause(timer*2)
      status_off
      led_off
      Keys_Released
      Verbalizer_Loop 
      time.Pause(timer*4)
      Verbalizer_Loop
     
    led_off
    status_off

PRI SaySomething  | timer
      timer := 200
      
      Update_this_Keys_State(3, TRUE)
      Verbalizer_Loop
      time.Pause(timer)

      Update_this_Keys_State(3, TRUE)
      Verbalizer_Loop
      time.Pause(timer)

      Update_this_Keys_State(3, FALSE)
      Verbalizer_Loop
      time.Pause(timer)

      Update_this_Keys_State(3, FALSE)
      Verbalizer_Loop
      time.Pause(timer)
     
PUB Main | current_count

  init
    
    repeat 'THE MAIN LOOP ################################
    
      time.Pause(100)
      
      pressure := AdjustTheScale(GetBreathPressure)
      Direction_Update
    '*********************     
    

      main_loops_count++
      'set_params_to_bar(Direction_Bar_Level)
      
      if main_loops_count > (10-Direction_Bar_Level_at_Release) * 25 '36'from 12
        Keys_Released
      'else
      '  Param[7] := (Direction_Bar_Level- 1) * 2'10    volume
          
      Verbalizer_Loop
      
      
 
PRI AdjustTheScale(thePressure)
  thePressure := thePressure / 2
  thePressure := thePressure - 40
  return thePressure
  
PRI GetBreathPressure | i,  rolling_average
' using these globals
' smooth_operator
' Long smoothness[smooth_operator]
' Long smooth_operator_iterator
  smooth_operator_iterator := smooth_operator_iterator + 1
  if smooth_operator_iterator > smooth_operator
    smooth_operator_iterator := 0
  smoothness[smooth_operator_iterator] := adc.In(0)
  rolling_average := 0
  
  repeat i from 0 to smooth_operator
    rolling_average := rolling_average + smoothness[i]  
  rolling_average := rolling_average / smooth_operator
  
  return rolling_average
  
  'ASCII0_STREngine_1.integerToDecimal(log_count, 2)
  case x
    0 : return String("breath00.txt")
    1 : return String("breath01.txt")
    2 : return String("breath02.txt")
    3 : return String("breath03.txt")
    4 : return String("breath04.txt")
    5 : return String("breath05.txt")
    6 : return String("breath06.txt")
    7 : return String("breath07.txt")
    8 : return String("breath08.txt")
    9 : return String("breath09.txt")
    10 : return String("breath10.txt") 
  'return String("hrt1", ".txt")
  'x := String(stringo.integerToDecimal(log_count, 2))
  'return String("hrt", x, ".txt")

PRI led_on
  outa[led_pin] := 1

PRI led_off
  outa[led_pin] := 0

PRI status_on
  outa[status_pin] := 1
  
PRI status_off
  outa[status_pin] := 0
  

PUB RunBarGraph | modified_pressure

  'show the modified pressure
  repeat
    if pressure < 0
      modified_pressure := 0
    else
      modified_pressure := pressure
    outa[BAR_GRAPH_9..BAR_GRAPH_0] := 1<<modified_pressure - 1   'Continually set the value of the scaled pressure to the LED bar graph pins.
                                                        'Do a little bitwise manipulation to make the LEDs look nice.


DAT

{{
==================================================================================================================================
=                                                   TERMS OF USE: MIT License                                                    =                                                            
==================================================================================================================================
= Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation     = 
= files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,     =
= modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software =
= is furnished to do so, subject to the following conditions:                                                                    =
=                                                                                                                                =
= The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. =
=                                                                                                                                =
= THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE           =
= WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR          =
= COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,    =
= ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                          =
==================================================================================================================================
}} 