classdef (Sealed) Objects < handle
    %Objects Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        handles
        classtype
        IDs
    end
    
    methods (Access = private)
        function obj = Objects()
            obj.handles = [];
            obj.classtype = [];
            obj.IDs = [];
        end
    end
    
    methods (Static)
        function instance = get ()
            persistent singleInstance
            if isempty(singleInstance) || ~isvalid(singleInstance)
                singleInstance = Objects();
            end
            instance = singleInstance;
        end
        
        function [] = add(h,type,varargin)
            obj = Objects.get;
            if ~any(h == obj.handles)
                obj.handles{end+1} = h;
                obj.classtype{end+1} = type;
                if numel(varargin) > 0
                    obj.IDs(end+1) = varargin{1};
                else
                    obj.IDs(end+1) = [];
                end
            end
        end
        
        function [] = remove(h)
            obj = Objects.get;
            for ii = numel(obj.handles):-1:1
                if obj.handles{ii} == h
                    obj.handles(ii) = [];
                    obj.classtype(ii) = [];
                    obj.IDs(ii) = [];
                end
            end
        end
        
        function h = find(type,varargin)
            h = [];
            obj = Objects.get;
            if isempty(varargin)
                inds = find(strcmp(type,obj.classtype));
                if ~isempty(inds)
                    if numel(varargin) == 0
                        h = obj.handles(inds);
                    end
                end
            else
                ind = find((strcmp(type,obj.classtype)) & (obj.IDs == varargin{1}),1);
                if ~isempty(ind)
                    h = obj.handles{ind};
                end
            end
        end
        
        function delete()
            obj = Objects.get;
            for ii = numel(obj.handles):-1:1
                obj.handles{ii}.delete;
            end
            clear Objects;
        end
        
    end
    
end

