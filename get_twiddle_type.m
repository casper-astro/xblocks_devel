function twiddle_type = get_twiddle_type(Coeffs, biplex, opt_target, use_embedded)

opt_target

opt_logic = strcmp(opt_target, 'logic');


% Determine twiddle type from 'Coeffs'
if length(Coeffs) == 1,
    if Coeffs(1) == 0,
        %if used in biplex core and first stage
        if(strcmp(biplex, 'on')),
            twiddle_type = 'twiddle_pass_through';
        else
            twiddle_type = 'twiddle_coeff_0';
        end
    elseif Coeffs(1) == 1,
        twiddle_type = 'twiddle_coeff_1';
    else
        if opt_logic && use_embedded,
            twiddle_type = 'twiddle_general_dsp48e';
        elseif opt_logic,
            twiddle_type = 'twiddle_general_4mult';
        else
           twiddle_type = 'twiddle_general_3mult';
       end
    end
elseif length(Coeffs)==2 && Coeffs(1)==0 && Coeffs(2)==1 && StepPeriod==FFTSize-2,
    twiddle_type = 'twiddle_stage_2';
else
    if use_embedded,
        twiddle_type = 'twiddle_general_dsp48e';
    elseif opt_logic,
        twiddle_type = 'twiddle_general_4mult';
    else
        twiddle_type = 'twiddle_general_3mult';
    end
end


end
