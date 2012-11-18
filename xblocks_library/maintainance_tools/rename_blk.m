function rename_blk(varargin)

if isempty(varargin)
    disp('************************************************');
    disp('rename_blk:');
    disp('Syntax: ');
    disp('rename_blk(''old_blk_name'',''*name_of_old_blk*'',''new_blk_name'',''*name_of_new_blk*'',''verbose'',''on'' or ''off'' ');
    disp(' ');
    disp('See also: add_to_subblk_list(), rm_from_subblk_list(), get_dependlist()');
    disp(' ');
    disp('Block hierarchy information stored in file subblk_list.mat');
    disp('************************************************');
    return;
end

defaults = {'verbose', 'on'};

old_blk_name = get_var('old_blk_name', 'defaults', defaults, varargin{:});
new_blk_name = get_var('new_blk_name', 'defaults', defaults, varargin{:});
verbose = get_var('verbose', 'defaults', defaults, varargin{:});

if strcmp(verbose, 'on')
    disp('------------------------------');
    disp(['renaming block: ', old_blk_name, ' to: ', new_blk_name]);
    disp(' ');
    disp('------------------------------');
end



subblk_list = load('subblk_list',[old_blk_name,'_subblk_list']);
if strcmp(verbose, 'on')
    disp('------------------------------');
    disp('sub-blocks of the old block');
    disp(subblk_list);
    disp(fieldnames(subblk_list));
    disp('------------------------------');
end

subblk_list = subblk_list.([old_blk_name,'_subblk_list']);

% clear sub-block list for the old block name
new_subblk_list = {};
eval([[old_blk_name,'_subblk_list'] '=new_subblk_list;']);
save('subblk_list',[old_blk_name,'_subblk_list'],'-append');

% store the sub-block list under the new block name
eval([[new_blk_name,'_subblk_list'] '=subblk_list;']);
save('subblk_list',[new_blk_name,'_subblk_list'],'-append');

% deal with all the blocks that depend on the old block
parents_list_names = get_dependlist(old_blk_name, '-super'); % get a list of parent blocks, all end with '_init_xblock'
parents_list = cell(1, length(parents_list_names));
for i = 1:length(parents_list_names)
    temp_name = parents_list_names{i};
    parents_list_names{i} = temp_name(1:strfind(temp_name, '_init_xblock')-1);
    %parents_list{i} = load('subblk_list', parents_list_names{i});
end
if strcmp(verbose, 'on')
    disp('------------------------------');
    disp('parent-blocks of the old block');
    disp(parents_list_names);
    disp('------------------------------');
end
for i = 1:length(parents_list_names)
    rm_from_subblk_list('main_blk', parents_list_names{i}, 'sub_blks', {old_blk_name}, 'verbose', verbose);
    add_to_subblk_list('main_blk', parents_list_names{i}, 'sub_blks', {new_blk_name}, 'verbose', verbose);
end

end