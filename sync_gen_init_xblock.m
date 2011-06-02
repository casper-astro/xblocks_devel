%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011     Hong Chen                                          %
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
function sync_gen_init_xblock(sim_acc_len, fft_size, fft_simult_inputs, pfb_fir_taps, reorder_vec, scale, comp_latency)
%% inports
sync_period = xInport('sync_period');
sw_sync_pulse = xInport('sw_sync_pulse');

%% outports
xlsub2_sync_out = xOutport('sync_out');

%% diagram

if pfb_fir_taps < 1,
    errordlg('Sync Generator: pfb_fir length must be >= 1')
end

% Calculate the LCM( FFT reorder delays )
lcm_reorder = 1;
for i=1:length(reorder_vec),
    lcm_reorder = lcm(lcm_reorder, reorder_vec(i));
end

sim_sync_period = scale * sim_acc_len * pfb_fir_taps * fft_size * lcm_reorder / fft_simult_inputs;


% block: untitled/sync_gen/Counter3
xlsub2_Logical1_out1 = xSignal;
xlsub2_Counter3_out1 = xSignal;
xlsub2_Counter3 = xBlock(struct('source', 'Counter', 'name', 'Counter3'), ...
                         struct('n_bits', 32, ...
                                'rst', 'on', ...
                                'explicit_period', 'off', ...
                                'use_rpm', 'on'), ...
                         {xlsub2_Logical1_out1}, ...
                         {xlsub2_Counter3_out1});

% block: untitled/sync_gen/Logical
xlsub2_Relational_out1 = xSignal;
xlsub2_posedge2_out1 = xSignal;
xlsub2_Logical_out1 = xSignal;
xlsub2_Logical = xBlock(struct('source', 'Logical', 'name', 'Logical'), ...
                        struct('logical_function', 'OR', ...
                               'n_bits', 8, ...
                               'bin_pt', 2), ...
                        {xlsub2_Relational_out1, xlsub2_posedge2_out1}, ...
                        {xlsub2_Logical_out1});

% block: untitled/sync_gen/Logical1
xlsub2_Logical1 = xBlock(struct('source', 'Logical', 'name', 'Logical1'), ...
                         struct('logical_function', 'OR', ...
                                'n_bits', 8, ...
                                'bin_pt', 2), ...
                         {xlsub2_Relational_out1, xlsub2_posedge2_out1}, ...
                         {xlsub2_Logical1_out1});

% block: untitled/sync_gen/Mux
xlsub2_Relational1_out1 = xSignal;
xlsub2_sync_period_const_out1 = xSignal;
xlsub2_sync_period_out1 = xSignal;
xlsub2_Mux_out1 = xSignal;
xlsub2_Mux = xBlock(struct('source', 'Mux', 'name', 'Mux'), ...
                    [], ...
                    {xlsub2_Relational1_out1, xlsub2_sync_period_const_out1, sync_period}, ...
                    {xlsub2_Mux_out1});

% block: untitled/sync_gen/Relational
xlsub2_Relational = xBlock(struct('source', 'Relational', 'name', 'Relational'), ...
                           struct('latency', comp_latency), ...
                           {xlsub2_Mux_out1, xlsub2_Counter3_out1}, ...
                           {xlsub2_Relational_out1});

% block: untitled/sync_gen/Relational1
xlsub2_zero_out1 = xSignal;
xlsub2_Relational1 = xBlock(struct('source', 'Relational', 'name', 'Relational1'), ...
                            struct('mode', 'a!=b', ...
                                   'latency', comp_latency), ...
                            {xlsub2_zero_out1, sync_period}, ...
                            {xlsub2_Relational1_out1});

% block: untitled/sync_gen/Slice2
xlsub2_sw_sync_pulse_out1 = xSignal;
xlsub2_Slice2_out1 = xSignal;
xlsub2_Slice2 = xBlock(struct('source', 'Slice', 'name', 'Slice2'), ...
                       struct('boolean_output', 'on', ...
                              'mode', 'Lower Bit Location + Width'), ...
                       {sw_sync_pulse}, ...
                       {xlsub2_Slice2_out1});

% block: untitled/sync_gen/posedge1
xlsub2_posedge1 = xBlock(struct('source', 'casper_library_misc/posedge', 'name', 'posedge1'), ...
                         [], ...
                         {xlsub2_Logical_out1}, ...
                         {xlsub2_sync_out});

% block: untitled/sync_gen/posedge2
xlsub2_posedge2 = xBlock(struct('source', 'casper_library_misc/posedge', 'name', 'posedge2'), ...
                         [], ...
                         {xlsub2_Slice2_out1}, ...
                         {xlsub2_posedge2_out1});

xlsub2_sync_period_const = xBlock(struct('source', 'Constant', 'name', 'sync_period_const'), ...
                                  struct('const', sim_sync_period - comp_latency, ...
                                         'n_bits', 32, ...
                                         'bin_pt', 0), ...
                                  {}, ...
                                  {xlsub2_sync_period_const_out1});

% block: untitled/sync_gen/zero
xlsub2_zero = xBlock(struct('source', 'Constant', 'name', 'zero'), ...
                     struct('arith_type', 'Unsigned', ...
                            'const', 0, ...
                            'n_bits', 32, ...
                            'bin_pt', 0, ...
                            'explicit_period', 'on'), ...
                     {}, ...
                     {xlsub2_zero_out1});



end

