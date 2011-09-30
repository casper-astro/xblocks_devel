% mixer_init(blk, varargin)
%
% blk = The block to initialize.
% varargin = {'varname', 'value', ...} pairs
%
% Valid varnames for this block are:
% freq_div = The (power of 2) denominator of the mixing frequency.
% freq = The numerator of the mixing frequency
% nstreams = The number of parallel streams provided
% n_bits = The bitwidth of samples out
% bram_latency = The latency of sine/cos lookup table
% mult_latency = The latency of mixer multiplier

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

function mixer_init_xblock(blk,varargin)

% Declare any default values for arguments you might like.
defaults = {'n_bits', 8, 'bram_latency', 2, 'mult_latency', 3};


freq_div = get_var('freq_div','defaults', defaults, varargin{:});
freq = get_var('freq','defaults', defaults, varargin{:});
nstreams = get_var('nstreams','defaults', defaults, varargin{:});
n_bits = get_var('n_bits','defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency','defaults', defaults, varargin{:});
mult_latency = get_var('mult_latency','defaults', defaults, varargin{:});

counter_step = mod(nstreams*freq,freq_div);

if log2(nstreams) ~= round(log2(nstreams)),
    disp('The number of inputs must be a positive power of 2 integer');
    error('The number of inputs must be a positive power of 2 integer');
    return;
end

sync_in = xInport('sync');
sync_out = xOutport('sync_out');
sync_delay = xBlock(struct('source', 'xbsIndex_r4/Delay', 'name', 'delay'), ...
    {'latency', mult_latency}, ...
    {sync_in}, ...
    {sync_out});


dds_outs = cell(1,2*nstreams);
for i =1:2*nstreams
    dds_outs{i} = xSignal(['dds_out', num2str(i)]);
end
if counter_step ~= 0,
    dds_blk = xBlock(struct('name', 'dds', 'source', str2func('dds_init_xblock')), ...
        {[blk, '/dds'], ...
        'num_lo', nstreams, 'freq', freq,...
        'freq_div', freq_div, 'n_bits', n_bits, 'latency',2}, ...
        {sync_in}, ...
        dds_outs);
else
    dds_blk = xBlock(struct('name', 'dds', 'source', str2func('dds_init_xblock')), ...
        {[blk, '/dds'], ...
        'num_lo', nstreams, 'freq', freq,...
        'freq_div', freq_div, 'n_bits', n_bits, 'latency',2}, ...
        {}, ...
        dds_outs);
end


inports = cell(1,nstreams);
rcmult_blks = cell(1,nstreams);
real_outs = cell(1,nstreams);
imag_outs = cell(1,nstreams);
for i=1:nstreams,
    rcmult = ['rcmult',num2str(i)];
    din = ['din',num2str(i)];
    real = ['real',num2str(i)];
    imag = ['imag',num2str(i)];
    inports{i} = xInport(din);
    real_outs{i} = xOutport(real);
    imag_outs{i} = xOutport(imag);
    
    rcmult_blks{i} = xBlock(struct('name',rcmult, 'source', str2func('rcmult_init_xblock')), ...
        {[blk, '/', rcmult], 'latency', mult_latency}, ...
        {inports{i}, dds_outs{i*2-1}, dds_outs{i*2}}, ...
        {real_outs{i}, imag_outs{i}});
end


% Set attribute format string (block annotation)
if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
    % Set attribute format string (block annotation)
    annotation=sprintf('lo at -%d/%d',freq, freq_div);
    set_param(blk,'AttributesFormatString',annotation);
end

end

