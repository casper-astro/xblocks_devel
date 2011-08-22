%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011    Hong Chen                                           %
%   Copyright (C) 2007 Terry Filiba, Aaron Parsons                            %
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
function fir_tap_init_xblock(blk, factor, latency, coeff_bit_width, coeff_bin_pt)


%% inports
xlsub2_a = xInport('a');
xlsub2_b = xInport('b');

%% outports
xlsub2_a_out = xOutport('a_out');
xlsub2_b_out = xOutport('b_out');
xlsub2_real = xOutport('real');
xlsub2_imag = xOutport('imag');

%% diagram

% block: untitled/fir_tap/Constant
xlsub2_Constant_out1 = xSignal;
xlsub2_Constant = xBlock(struct('source', 'Constant', 'name', 'Constant'), ...
                         struct('const', factor, ...
                                'n_bits', coeff_bit_width, ...
                                'bin_pt', coeff_bin_pt, ...
                                'explicit_period', 'on'), ...
                         {}, ...
                         {xlsub2_Constant_out1});

% block: untitled/fir_tap/Mult
xlsub2_Mult = xBlock(struct('source', 'Mult', 'name', 'Mult'), ...
                     struct('n_bits', 18, ...
                            'bin_pt', 17, ...
                            'latency', latency, ...
                            'use_behavioral_HDL', 'on', ...
                            'use_rpm', 'off', ...
                            'placement_style', 'Rectangular shape'), ...
                     {xlsub2_Constant_out1, xlsub2_b}, ...
                     {xlsub2_imag});

% block: untitled/fir_tap/Mult1
xlsub2_Mult1 = xBlock(struct('source', 'Mult', 'name', 'Mult1'), ...
                      struct('n_bits', 18, ...
                             'bin_pt', 17, ...
                             'latency', latency, ...
                             'use_behavioral_HDL', 'on', ...
                             'use_rpm', 'off', ...
                             'placement_style', 'Rectangular shape'), ...
                      {xlsub2_Constant_out1, xlsub2_a}, ...
                      {xlsub2_real});

% block: untitled/fir_tap/Register
xlsub2_Register = xBlock(struct('source', 'Register', 'name', 'Register'), ...
                         [], ...
                         {xlsub2_a}, ...
                         {xlsub2_a_out});

% block: untitled/fir_tap/Register1
xlsub2_Register1 = xBlock(struct('source', 'Register', 'name', 'Register1'), ...
                          [], ...
                          {xlsub2_b}, ...
                          {xlsub2_b_out});



if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
end

end

