%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011    Hong Chen                                           %
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
function rm_from_subblk_list(varargin)

if isempty(varargin)
    disp('************************************************');
    disp('rm_from_subblk_list:');
    disp('Syntax: ');
    disp('rm_from_subblk_list(''main_blk'',''*name_of_main_blk*'',''sub_blks'',{*sub blocks*})');
    disp(' ');
    disp('See also: add_to_subblk_list(), rename_blk(), get_dependlist()');
    disp(' ');
    disp('Block hierarchy information stored in file subblk_list.mat');
    disp('************************************************');
end

defaults = {'verbose', 'on'};

main_blk = get_var('main_blk', 'defaults', defaults, varargin{:});
sub_blks = get_var('sub_blks', 'defaults', defaults, varargin{:});
verbose = get_var('verbose', 'defaults', defaults, varargin{:});

if ~iscell(sub_blks)
    disp('invalid sub block list!');
    return;
end

subblk_list = load('subblk_list',[main_blk,'_subblk_list']);

if isempty(subblk_list)
    disp('main block not found!')
    return;
end

new_subblk_list = subblk_list.([main_blk,'_subblk_list']);
if strcmp(verbose, 'on')
    disp(new_subblk_list);
end
to_remove = find(ismember(new_subblk_list,sub_blks)==1);

if strcmp(verbose, 'on')
    to_remove
end

new_subblk_list(to_remove)=[];
if strcmp(verbose, 'on')
    disp(new_subblk_list);
end

eval([[main_blk,'_subblk_list'] '=new_subblk_list;']);


save('subblk_list',[main_blk,'_subblk_list'],'-append');

if strcmp(verbose, 'on')
    disp(' ');
    disp('************************************************');
    disp('Sub block list updated!');
    disp(' ');
    disp(['Main block: ', main_blk]);
    disp('Depend list: ');
    dl = get_dependlist(main_blk);
    dl{:}
    disp('************************************************');
end

end