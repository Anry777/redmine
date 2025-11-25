module RedmineAgile
  module Patches
    module IssuesControllerPatch
      def self.included(base)
        base.class_eval do
          helper :agile_sprints
          include AgileSprintsHelper
        end
      end
    end
  end
end

unless IssuesController.included_modules.include?(RedmineAgile::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineAgile::Patches::IssuesControllerPatch)
end
