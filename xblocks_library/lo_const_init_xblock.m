%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://seti.ssl.berkeley.edu/casper/                                      %
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
function lo_const_init_xblock(blk, varargin)

defaults = {'n_bits', 8, 'phase', 0};


n_bits = get_var('n_bits','defaults', defaults, varargin{:});
phase= get_var('phase','defaults', defaults, varargin{:});


%% inports

%% outports
xlsub2_sin = xOutport('sin');
xlsub2_cos = xOutport('cos');

%% diagram

% block: lo_const_xblock_model/lo_const/const
xlsub2_const = xBlock(struct('source', 'Constant', 'name', 'const'), ...
                      struct('const', real(exp(phase*1j)), ...
                             'n_bits', n_bits, ...
                             'bin_pt', n_bits - 1, ...
                             'explicit_period', 'on'), ...
                      {}, ...
                      {xlsub2_cos});

% block: lo_const_xblock_model/lo_const/const1
xlsub2_const1 = xBlock(struct('source', 'Constant', 'name', 'const1'), ...
                       struct('const', -imag(exp(phase*1j)), ...
                              'n_bits', n_bits, ...
                              'bin_pt', n_bits - 1, ...
                              'explicit_period', 'on'), ...
                       {}, ...
                       {xlsub2_sin});

% Set attribute format string (block annotation)
if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
    annotation=sprintf('');
    set_param(blk,'AttributesFormatString',annotation);
end
end

