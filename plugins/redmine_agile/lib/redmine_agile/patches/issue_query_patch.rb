# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2025 RedmineUP
# http://www.redmineup.com/
#
# redmine_agile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_agile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_agile.  If not, see <http://www.gnu.org/licenses/>.

require_dependency 'issue'

module RedmineAgile
  module Patches
    module IssueQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method :issues_without_agile, :issues
          alias_method :issues, :issues_with_agile

          alias_method :issue_ids_without_agile, :issue_ids
          alias_method :issue_ids, :issue_ids_with_agile

          alias_method :available_columns_without_agile, :available_columns
          alias_method :available_columns, :available_columns_with_agile

          alias_method :initialize_available_filters_without_agile, :initialize_available_filters
          alias_method :initialize_available_filters, :initialize_available_filters_with_agile
        end
      end

      module InstanceMethods
        def issues_with_agile(options = {})
          options[:include] = (options[:include] || []) | [:agile_data]
          issues_without_agile(options)
        end

        def issues_with_agile_preload(options = {})
          issues = issues_without_agile(options)
          if issues.is_a?(ActiveRecord::Relation)
            issues = issues.preload(:agile_data)
            
            # Preload agile_color в зависимости от color_base
            color_base_value = respond_to?(:color_base) ? color_base : RedmineAgile.color_base
            if color_base_value == AgileColor::COLOR_GROUPS[:issue]
              issues = issues.preload(:agile_color)
            elsif color_base_value == AgileColor::COLOR_GROUPS[:tracker]
              issues = issues.preload(tracker: :agile_color)
            elsif color_base_value == AgileColor::COLOR_GROUPS[:priority]
              issues = issues.preload(priority: :agile_color)
            elsif color_base_value == AgileColor::COLOR_GROUPS[:project]
              issues = issues.preload(project: :agile_color)
            end
          end
          issues
        end

        def issue_ids_with_agile(options = {})
          options[:include] = (options[:include] || []) | [:agile_data]
          issue_ids_without_agile(options)
        end

        def available_columns_with_agile
          if @available_columns.blank?
            @available_columns = available_columns_without_agile
            @available_columns << QueryColumn.new(:story_points,
                                                  caption: :label_agile_story_points,
                                                  sortable: "#{AgileData.table_name}.story_points")
            @available_columns << QueryColumn.new(:agile_sprint,
                                                  caption: :field_agile_sprint) if User.current.allowed_to?(:view_agile_queries, nil, global: true)
          else
            available_columns_without_agile
          end
          @available_columns
        end

        def initialize_available_filters_with_agile
          initialize_available_filters_without_agile
          if User.current.allowed_to?(:view_agile_queries, project, global: true)
            add_available_filter('agile_sprints',
                                 type: :list_optional,
                                 name: l(:field_agile_sprint),
                                 values: lambda { agile_sprint_values })
          end
          @available_filters
        end

        def agile_sprint_values
          sprints = if project
                      project.shared_agile_sprints
                    else
                      AgileSprint.visible.to_a
                    end

          AgileSprint.sort_by_status(sprints)
                     .collect { |s| ["#{s.project.name} - #{s.name}", s.id.to_s, l("label_agile_sprint_status_#{s.status_name}")] }
        end

        def sql_for_agile_sprints_field(_field, operator, value)
          compare = case operator
                    when '=', '*'
                      'IN'
                    when '!', '!*'
                      'NOT IN'
                    else
                      'IN'
                    end

          condition = value.any?(&:present?) ? "IN (#{value.join(',')})" : 'IS NOT NULL'
          sprint_select = "SELECT #{AgileData.table_name}.issue_id FROM #{AgileData.table_name}
                           WHERE #{AgileData.table_name}.agile_sprint_id #{condition}"

          "(#{Issue.table_name}.id #{compare} (#{sprint_select}))"
        end
      end
    end
  end
end

if (ActiveRecord::Base.connection.tables.include?('queries') rescue false) &&
   IssueQuery.included_modules.exclude?(RedmineAgile::Patches::IssueQueryPatch)
  IssueQuery.send(:include, RedmineAgile::Patches::IssueQueryPatch)
end
