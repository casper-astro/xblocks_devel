%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011      Hong Chen                                         %
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
function [param,values] = manual_init_running(blk,init_script_name,setting)
%% running init script for current block
%%% Inputs:
% blk = the block to renew
% init_script_name,  type: string   the name of the init file
% settings = {'vername',value, ...} pairs
%%% Outputs:
% param = {'vername,value,...} pairs with all the user data
% values = {value, ...}  retrieves all the values from the param
%%%%%  to find out the parameter names, run it with setting={}
%%%%%  to reset some of the parameters, run it as
%%%%%  settings={'vername1',value1, 'vername2',value2, ...};
% example: [params,values]=manual_init_running(gcb, 'fir_col_init', {'n_inputs',2})
% then you can run fir_col_init_xblock(values{:});


%% 

dialogparam = getfield(get_param(gcb,'UserData'),'parameters');
try
    dialogparam=rmfield(dialogparam,'defaults');
catch
    err=1;
end
disp('Use Data:');
names = fieldnames(dialogparam)
size_names=size(names);
num_names=size_names(1);
param=cell(1,2*num_names);
for i=1:num_names,
    param{1,2*i-1}=names{i,1};
    if (~isnan(get_var(names{i,1},setting{:})))
        param{1,2*i}=get_var(names{i,1},setting{:});
    else
        param{1,2*i}=getfield(dialogparam,names{i,1});
    end;
end
param
values=param(2:2:end);

init_func=str2func(init_script_name);
init_func(blk, param{:});

