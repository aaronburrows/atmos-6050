;----------------------------------------------------------------------;
; Environmental Instrumentation - ATMOS 6050                           ;
; Laboratory Assignment No. 2                                          ;
; "Time Response and Introduction to the CR1000 Datalogger"            ;
;                                                                      ;
; (C) 2016 Adam C. Abernathy, adamabernathy@gmail.com                  ;
; All rights reserved.                                                 ;
;                                                                      ;
; Dependencies                                                         ;
; ------------                                                         ;
; Islay IDL Library : https://github.com/adamabernathy/islay           ;
;                                                                      ;
; History                                                              ;
; -------                                                              ;
; v0.0.1 - Initial Release, January 19, 2016                           ;
;                                                                      ;
;----------------------------------------------------------------------;


pro lab2
compile_opt idl2

    ;------------------------------------------------------------------;
    ; Initialization & define user values                              ;
    ;------------------------------------------------------------------;
    f = 'CR1000_Table1.dat'             ; file to read

    header_lines = 4                    ; no. lines in header
    line_start   = 1610                 ; where our data starts
    line_finish  = 1800                 ; where our data ends

    rng          = [0, 25]              ; time range to plot
    var_col         = 3                 ; tempertaure column
    idx_col      = 1                    ; record index column

    do_plot      = 'yes'                 ; create plots?

    ;------------------------------------------------------------------;
    ; Read in & treat data                                             ;
    ; !! Remember that 'read_text()' returns the values as a string.   ;
    ;------------------------------------------------------------------;
    result = read_text(f)                   ; read in file
    result = result[*,header_lines : -1]    ; remove header

    ;
    ; We want to trim the data object to just the values that we want
    ; to work with in our calculations. We also know that the dt values
    ; are in incriments of 1 second. Therefore we are not concerned
    ; with the time stamp array.
    ;
    darr   = float(result[1:-1, line_start:line_finish]) ; data array
    result = 0

    ;
    ; Find unique points on the plot. We first look for the start
    ; and ending temperature as well as the maximum temperature. By
    ; knowing where the max temperture is we can assume that that is
    ; the exact moment the person released their fingers from the
    ; thermocoupler.
    ;
    temp_init    = darr[var_col, 0]      ; assumes 1st record
    temp_final   = darr[var_col, -1]
    temp_max     = max(darr[var_col, *])
    temp_max_idx = where(darr[var_col, *] eq max(darr[var_col, *]))

    ;
    ; Now we will re-index our data once again and remove any data
    ; from before the maximum temperture was recorded.
    ;
    TC_temp = reform(darr[var_col, temp_max_idx:-1])

    ; Calculate the temperature ratio
    temp_ratio = calc_tempRatio(TC_temp, temp_init, temp_final)

    ; Find T(tau) at tau = 0.368, 0.135
    tau   = [0.368, 0.135]
    temp1 = calc_tau(tau[0], temp_init, temp_final)
    temp2 = calc_tau(tau[1], temp_init, temp_final)

    ;
    ; Now find the linear fit. We will use the dummyx variable later
    ; to plot the values.
    ;
    dummyx = indgen(n_elements(temp_ratio[rng[0]:rng[1]]))
    err    = sqrt(abs(temp_ratio[rng[0]:rng[1]]))
    result = linfit(dummyx, temp_ratio[rng[0]:rng[1]], $
                    measure_errors=err)

    ; Linear fit line (y=mx+b), used for plotting
    fit = (result[1] * dummyx) + result[0]

    ; Calculate Time(tau)
    time1 = calc_timeTau(tau[0], result)
    time2 = calc_timeTau(tau[1], result)

    print, 'tau, time(tau), temp(tau)'
    print, tau[0], time1, temp1
    print, tau[1], time2, temp2

    ; Find the slope of the line from the tau(x) values.
    tau_slope = ( alog((tau[0] * 100.)) - alog((tau[1] * 100.)) ) / $
                ( time1 - time2 )

    ; Find tau (response time)
    tau_response = -1.0 / tau_slope

    ; Calculate dT/dt
    temp_response = fltarr(n_elements(TC_temp))
    for i = 0, n_elements(temp_response) - 1 do begin
        temp_response[i] = (-1.0 / tau_response) * $
                           (TC_temp[i] - temp_final)
    endfor

    print, 'tau slope ',        tau_slope
    print, 'tau response time', tau_response


    ;------------------------------------------------------------------;
    ; Plot the results                                                 ;
    ;------------------------------------------------------------------;
    if do_plot eq 'yes' then begin

        ;
        ; Plot the thermocouple with a linear fit
        ;
        p1 = plot(dummyx[rng[0]:rng[1]], temp_ratio[rng[0]:rng[1]], $
                  xrange = rng, yrange=[0, 80], $
                  title  = 'Type-T Thermocouple Temperature (RATIO)', $
                  xtitle = 'Time (seconds)', /xstyle, $
                  ytitle = 'Temperature Ratio (%)', /ystyle, $
                  symbol = 'o', linestyle = 'solid', thick = 2, $
                  /sym_filled)

        p1 = plot(dummyx, fit, /overplot, $
                  thick = 2, color='red', linestyle='solid')

        ; tau(1)
        p1 = plot(/overplot, $
                  [min(dummyx), max(dummyx)], $
                  [tau[0] * 100., tau[0] * 100.], $
                  thick = 2, linestyle = 'dashed')

        ; tau(2)
        p1 = plot(/overplot, $
                  [min(dummyx), max(dummyx)], $
                  [tau[1] * 100., tau[1] * 100.], $
                  thick = 2, linestyle = 'dashed')

        p1 = plot([time1], [tau[0] * 100.], /overplot, $
                  symbol = 'o', sym_size = 1.25, /sym_filled, $
                  linestyle = 'none', color ='red')

        p1 = plot([time2], [tau[1] * 100.], /overplot, $
                  symbol = 'o', sym_size = 1.25, /sym_filled, $
                  linestyle = 'none', color ='red')


        ;
        ; Plot the temperature response in a linear fashion
        ;
        p2 = plot(dummyx[rng[0]:rng[1]], $
                  alog(temp_response[rng[0]:rng[1]] * (-1)), $
                  xrange = rng, $
                  title  = 'Type-T Thermocouple Temperature Response', $
                  xtitle = 'Time (seconds)', /xstyle, $
                  ytitle = 'Temperature Decay (Degrees C)', /ystyle, $
                  symbol = 'o', linestyle = 'solid', thick = 3, $
                  /sym_filled)

    endif ; do_plot

end




;----------------------------------------------------------------------;
; Calculate the temperature ratio                                      ;
;                                                                      ;
;                                                                      ;
;           Variable  Description            Dimension                 ;
; -------------------------------------------------------------------- ;
; In:       (T)       Temperature,           (array or scaler)         ;
;           (Ti)      Initial temperature,   (scaler)                  ;
;           (Tf)      Final temperature,     (scaler)                  ;
;                                                                      ;
; Return:   (Tr)      Temperature ratio,     (array or scaler)         ;
;----------------------------------------------------------------------;
function calc_tempRatio, T, Ti, Tf
compile_opt idl2

    soln = fltarr(n_elements(T))
    C1   = Tf - Ti                  ; set as a constant for performance

    for i = 0, n_elements(soln) - 1 do begin
        soln[i] = ( T[i] - Tf ) / C1
    endfor

    return, soln

end




;----------------------------------------------------------------------;
; Calculate Tau                                                        ;
;                                                                      ;
;                                                                      ;
;           Variable  Description            Dimension                 ;
; -------------------------------------------------------------------- ;
; In:       (tau)     tau (0.368, 0.135),    (scalar)                  ;
;           (Ti)      Initial temperature,   (scaler)                  ;
;           (Tf)      Final temperature,     (scaler)                  ;
;                                                                      ;
; Return:   (T)       Temperature at tau(x), (scaler)                  ;
;----------------------------------------------------------------------;
function calc_tau, tau, Ti, Tf
compile_opt idl2

    return, tau * (Ti - Tf) + Tf

end




;----------------------------------------------------------------------;
; Calculate the Time(Tau)                                              ;
;                                                                      ;
;           Variable  Description            Dimension                 ;
; -------------------------------------------------------------------- ;
; In:       (tau)     tau (0.368, 0.135),    (scalar)                  ;
;           (fit)     linfit() return,       (array)                   ;
;                                                                      ;
; Return:   (time)    time (seconds) at tau, (scaler)                  ;
;----------------------------------------------------------------------;
function calc_timeTau, tau, fit
compile_opt idl2

    return, ( (tau * 100.) - fit[0]) / (fit[1])

end
