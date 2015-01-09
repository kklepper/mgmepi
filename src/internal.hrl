%% =============================================================================
%% =============================================================================

-include("../include/mgmepi.hrl").

%% == define ==

-define(FS, ": ").
-define(LS, $\n).

-define(IS_BACKUP_ID(T), (is_integer(T) and (0 =< T))).

-define(IS_BACKUP_WAIT(T), (is_integer(T) and (0 =< T) and (2 >= T))).

-define(IS_BOOLEAN(T), (is_integer(T) and (0 =< T) and (1 >= T))).

-define(IS_EVENT_CATEGORY(T), (is_integer(T)
                               and (?NDB_MGM_MIN_EVENT_CATEGORY =< T)
                               and (?NDB_MGM_MAX_EVENT_CATEGORY >= T))).

-define(IS_EVENT_SEVERITY(T), (is_integer(T)
                               and (?NDB_MGM_MIN_EVENT_SEVERITY =< T)
                               and (?NDB_MGM_MAX_EVENT_SEVERITY >= T))).

-define(IS_LOGLEVEL(T), (is_integer(T) and (0 =< T) and (15 >= T))).

-define(IS_NODE(T), (is_integer(T) and (1 =< T) and (?MAX_NODES_ID >= T))).

-define(IS_NODE_TYPE(T), (is_integer(T)
                          and (?NDB_MGM_NODE_TYPE_MIN =< T)
                          and (?NDB_MGM_NODE_TYPE_MAX >  T))).

-define(IS_VERSION(T), (is_integer(T))). % > 5.1 (restart:V2)
