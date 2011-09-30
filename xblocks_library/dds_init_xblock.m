%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://seti.ssl.berkeley.edu/casper/                                      %
%   Copyright (C) 2006 David MacMahon, Aaron Parsons                          %
%   Copyright (C) 2011 Hong Chen                                              %
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

function dds_init_xblock(blk,varargin)
% dds_init(blk, varargin)
%
% blk = The block to initialize.
% varargin = {'varname', 'value', ...} pairs
%
% Valid varnames for this block are:
% freq_div = The (power of 2) denominator of the mixing frequency.
% freq = The numerator of the mixing frequency
% num_lo = The number of parallel streams provided
% n_bits = The bitwidth of samples out
% latency = The latency of sine/cos lookup table

% Declare any default values for arguments you might like.
defaults = {'num_lo', 1, 'n_bits', 8, 'latency', 2};


freq_div = get_var('freq_div','defaults', defaults, varargin{:});
freq = get_var('freq','defaults', defaults, varargin{:});
num_lo = get_var('num_lo','defaults', defaults, varargin{:});
n_bits = get_var('n_bits','defaults', defaults, varargin{:});
latency = get_var('latency','defaults', defaults, varargin{:});

counter_width = log2(freq_div);
counter_step = mod(num_lo*freq,freq_div);

if num_lo < 1 || log2(num_lo) ~= round(log2(num_lo))
    disp('The number of parallel LOs must be a power of 2 no less than 1');
    error('The number of parallel LOs must be a power of 2 no less than 1');
    return;
end
if freq < 0 || freq ~= round(freq)
    disp('The frequency factor must be a positive integer');
    error('The frequency factor must be a positive integer');
    return;
end

if freq_div <= 0 || freq_div < num_lo || freq_div ~= round(freq_div) || freq_div/num_lo ~= round(freq_div/num_lo) || log2(freq_div) ~= round(log2(freq_div))
    disp('The frequency factor must be a positive power of 2 integer multiples of the number of LOs');
    error('The frequency factor must be a positive power of 2 integer multiples of the number of LOs');
    return;
end

sin_out = cell(1,num_lo);
cos_out = cell(1,num_lo);
lo_blks = cell(1,num_lo);
if counter_step ~=0 
    inport = xInport('sync');
end
for i=0:num_lo-1,
    sin_name = ['sin',num2str(i)];
    cos_name = ['cos',num2str(i)];
    % Add ports
    sin_out{i+1} = xOutport(sin_name);
    cos_out{i+1} = xOutport(cos_name);
    % Add LOs
    if counter_step == 0,
        lo_name = ['lo_const',num2str(i)];
        lo_blks{i+1} = xBlock(struct('name', lo_name, 'source',str2func('lo_const_init_xblock')), ...
            {[blk, '/',lo_name], ...
            'n_bits', n_bits, ...
            'phase', 2*pi*freq*i/freq_div}, ...
            {}, ...
            {sin_out{i+1}, cos_out{i+1}});
    else
        lo_name = ['lo_osc',num2str(i)];
        lo_blks{i+1} = xBlock(struct('name', lo_name, 'source', str2func('lo_osc_init_xblock')), ...
            {[blk, '/', lo_name], ...
            'n_bits', n_bits, 'latency', latency, ...
            'counter_width', counter_width, 'counter_start', mod(i*freq,freq_div), ...
            'counter_step', counter_step}, ...
            {inport}, ...
            {sin_out{i+1}, cos_out{i+1}});
    end  
end


% Set attribute format string (block annotation)
if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
    % Set attribute format string (block annotation)
    annotation=sprintf('lo at -%d/%d',freq, freq_div);
    set_param(blk,'AttributesFormatString',annotation);
end

end
