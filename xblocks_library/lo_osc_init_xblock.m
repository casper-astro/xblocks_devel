%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://seti.ssl.berkeley.edu/casper/                                      %
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

function lo_osc_init_xblock(blk,varargin)

defaults = {};

counter_width = get_var('counter_width','defaults', defaults, varargin{:});
counter_start = get_var('counter_start','defaults', defaults, varargin{:});
counter_step = get_var('counter_step','defaults', defaults, varargin{:});
n_bits = get_var('n_bits','defaults', defaults, varargin{:});
latency = get_var('latency','defaults', defaults, varargin{:});


inport = xInport('sync');
sin_out = xOutport('sin');
cos_out = xOutport('cos');

%forces counter to be larger than 3 bits so
%that RAM has more than 2 bit address to prevent 
%error
counter_out = xSignal('counter_out');
if(counter_width < 3),
    count = counter_width+2;
    counter_blk = xBlock(struct('source','Counter', 'name', 'counter'), ...
        {'n_bits',counter_width+2, ...
        'start_count', counter_start*4, ...
        'rst', 'on', ...
        'cnt_by_val', counter_step*4}, ...
        {inport}, ...
        {counter_out});
else
    count = counter_width;
    counter_blk = xBlock(struct('source','Counter', 'name', 'counter'), ...
        {'n_bits',counter_width, ...
        'rst', 'on', ...
        'start_count', counter_start, ...
        'cnt_by_val', counter_step}, ...
        {inport}, ...
        {counter_out});
end

sincos_blk = xBlock(struct('source', str2func('sincos_init_xblock'), 'name', 'sincos'), ...
   {[blk, '/sincos'], ...
    'func', 'sine and cosine', 'neg_sin', 'on', ...
    'neg_cos', 'off', 'symmetric', 'off', ...
    'handle_sync', 'off', 'depth_bits', count, ...
    'bit_width', n_bits, ...
    'bram_latency', latency}, ...
    {counter_out}, ...
    {sin_out, cos_out});

% Set attribute format string (block annotation)
if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
    annotation=sprintf('');
    set_param(blk,'AttributesFormatString',annotation);
end

end
