%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011    Hong Chen                                           %
%   Copyright (C) 2006 David MacMahon, Aaron Parsons                          %
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
function fir_dbl_col_init_xblock(blk,n_inputs, coeff, add_latency, mult_latency, coeff_bit_width, coeff_bin_pt, adder_tree_hdl)

%%% haven't complete yet

%% inports
xlsub2_real=cell(n_inputs,1);
xlsub2_imag=cell(n_inputs,1);
xlsub2_real_back=cell(n_inputs,1);
xlsub2_imag_back=cell(n_inputs,1);
for i = 1:n_inputs,
    xlsub2_real{i} = xInport(['real',num2str(i)]);
    xlsub2_imag{i} = xInport(['imag',num2str(i)]);
end
for i=1:n_inputs,
    xlsub2_real_back{i}=xInport(['real_back',num2str(i)]);
    xlsub2_imag_back{i}=xInport(['imag_back',num2str(i)]);
end


%% outports
xlsub2_real_out=cell(n_inputs,1);
xlsub2_imag_out=cell(n_inputs,1);
xlsub2_real_back_out=cell(n_inputs,1);
xlsub2_imag_back_out=cell(n_inputs,1);
for i = 1:n_inputs,
    xlsub2_real_out{i} = xOutport(['real_out',num2str(i)]);
    xlsub2_imag_out{i} = xOutport(['imag_out',num2str(i)]);
end
for i = 1:n_inputs,
    xlsub2_real_back_out{i} = xOutport(['real_back_out',num2str(i)]);
    xlsub2_imag_back_out{i} = xOutport(['imag_back_out',num2str(i)]);
end
xlsub2_real_sum = xOutport('real_sum');
xlsub2_imag_sum = xOutport('imag_sum');


%% diagram
xlsub2_fir_dbl_tap=cell(1,n_inputs);
xlsub2_fir_dbl_tap_out=cell(2,n_inputs);
for i = 1:n_inputs,
    % block: half_band_xblock/Subsystem/parallel_fir/f0/fir_col1/fir_dbl_tap(i)
    xlsub2_fir_dbl_tap_out{1,i}=xSignal(['xlsub2_fir_dbl_tap',num2str(i),'_real']);
    xlsub2_fir_dbl_tap_out{2,i}=xSignal(['xlsub2_fir_dbl_tap',num2str(i),'_image']);
    xlsub2_fir_dbl_tap{i} = xBlock(struct('source', str2func('fir_dbl_tap_init_xblock'), 'name', ['fir_dbl_tap',num2str(i)]), ...
                                 {[blk,'/','fir_dbl_tap',num2str(i)], coeff(i),add_latency,mult_latency,coeff_bit_width,coeff_bin_pt},...
                             {xlsub2_real{i}, xlsub2_imag{i}, xlsub2_real_back{n_inputs-i+1}, xlsub2_imag_back{n_inputs-i+1}},...
                             {xlsub2_real_out{i}, xlsub2_imag_out{i}, xlsub2_real_back_out{n_inputs-i+1}, xlsub2_imag_back_out{n_inputs-i+1},xlsub2_fir_dbl_tap_out{1,i}, xlsub2_fir_dbl_tap_out{2,i}});

end

if n_inputs==1,
    xlsub2_real_sum.bind(xlsub2_fir_dbl_tap_out{1,1});
    xlsub2_imag_sum.bind(xlsub2_fir_dbl_tap_out{2,1});
else
    %constant    
    xlsub2_Constant1_out=xSignal('Constant1_out');
    xlsub2_Constant1 = xBlock(struct('source', 'Constant', 'name', 'Constant1'), ...
                             struct('explicit_period', 'on'), ...
                             {}, ...
                             {xlsub2_Constant1_out});
    xlsub2_Constant2_out=xSignal('Constant2_out');                     
    xlsub2_Constant2 = xBlock(struct('source', 'Constant', 'name', 'Constant2'), ...
                             struct('explicit_period', 'on'), ...
                             {}, ...
                             {xlsub2_Constant2_out});
    %adder_tree
    xlsub2_adder_tree1_out1=xSignal('adder_tree1_out');
    xlsub2_adder_tree1=xBlock(struct('source',str2func('adder_tree_lib_init_xblock'),'name','adder_tree1'), ...
                            {[blk, '/adder_tree1'], ...
                             'n_inputs',n_inputs,...
                             'latency', add_latency, ...
                             'first_stage_hdl', adder_tree_hdl} , ... 
                              [{xlsub2_Constant1_out},xlsub2_fir_dbl_tap_out(1,1:n_inputs)],...
                              {xlsub2_adder_tree1_out1,xlsub2_real_sum});
    xlsub2_adder_tree2_out1=xSignal('adder_tree2_out1');                      
    xlsub2_adder_tree2=xBlock(struct('source',str2func('adder_tree_lib_init_xblock'),'name','adder_tree2'), ...
                            {[blk,'/adder_tree2'], ...
                             'n_inputs',n_inputs,...
                             'latency', add_latency, ...
                             'first_stage_hdl',adder_tree_hdl} , ... 
                              [{xlsub2_Constant2_out},xlsub2_fir_dbl_tap_out(2,1:n_inputs)],...
                              {xlsub2_adder_tree2_out1,xlsub2_imag_sum});
    %terminator
    xlsub2_Terminator1 = xBlock('Terminator',...
                               [], ...
                               {xlsub2_adder_tree1_out1}, ...
                               {});
    xlsub2_Terminator2 = xBlock('Terminator',...
                               [], ...
                               {xlsub2_adder_tree2_out1}, ...
                               {});

end

if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
end
end

