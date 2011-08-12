%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011 Suraj Gowda    Hong Chen                               %
%                                                                             %
%   This program is free software; you can redistribute it and/or modify      %
%   it under the terms of the GNU General Public License as published by      %
%   the Free Software Foundation; either version 2 of the License, or         %
%   (at your option) any later version.                                       %
%                                                                             %
%   This program is distributed in the hope that it will be useful,           %
%   but WITHOUT ANY WARRANTY; without even the implied warranty of            %
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             %
%   GNU General Public License for more details.                              %
%                                                                             %
%   You should have received a copy of the GNU General Public License along   %
%   with this program; if not, write to the Free Software Foundation, Inc.,   %
%   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.               %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function twiddle_type = get_twiddle_type(Coeffs, biplex, opt_target, use_embedded,StepPeriod,FFTSize)


opt_logic = strcmp(opt_target, 'logic');
use_embedded = strcmp(use_embedded,'on');


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
