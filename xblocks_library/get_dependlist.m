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
function dependlist = get_dependlist(blk_name,varargin)
%% Running with blk_name only:
%  get all subblocks of the target block (down to any level)
%  return a cell array of the _init_xblock.m files of those blocks
%% Running with extra parameter '-super'
%  get all blocks that directly depend on the target block
%  return a cell array of the _init_xblock.m files of those blocks


if isempty(varargin)
    subblk_list = load('subblk_list',[blk_name,'_subblk_list']);

    if ~isempty(fieldnames(subblk_list))
        subblocks = subblk_list.([blk_name,'_subblk_list']);
    else
        subblocks = {};
    end

    dependlist = {strcat(blk_name,'_init_xblock')};
    for i = 1:length(subblocks)
        temp_list = get_dependlist(subblocks{i});
        dependlist = [dependlist, temp_list{:}];
        dependlist = unique(dependlist);
    end

    dependlist = unique(dependlist);
elseif strcmp(varargin{1},'-super')
    recorded_subblk_names = who('-file','subblk_list.mat');
    recorded_subblk_lists = cell(1,length(recorded_subblk_names));
    super_blk_names = {};
    
    for i=1:length(recorded_subblk_names)
        recorded_subblk_lists{i} = load('subblk_list',recorded_subblk_names{i});
        if ismember(blk_name,recorded_subblk_lists{i}.(recorded_subblk_names{i}))
            super_blk_name_idx = findstr(recorded_subblk_names{i},'_subblk_list');
            super_blk_name = recorded_subblk_names{i}(1:super_blk_name_idx-1);
            super_blk_names = [super_blk_names,{[super_blk_name,'_init_xblock']}];
        end
    end
    
    dependlist =super_blk_names;
end


end