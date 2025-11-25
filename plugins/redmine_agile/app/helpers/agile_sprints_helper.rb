module AgileSprintsHelper
  def sprint_values_for_select_for(project)
    project_sprints = project.shared_agile_sprints.available
    return [] unless project_sprints.any?

    future_sprints = project_sprints.where(status: AgileSprint::OPEN).where('start_date >= ? ', Date.today)
    active_sprints = project_sprints.where(status: AgileSprint::ACTIVE)
    old_sprints = project_sprints.where(status: AgileSprint::OPEN).where('start_date < ? ', Date.today)

    grouped_sprints = []
    grouped_sprints << [l('label_agile_sprint_list_future'), future_sprints.map { |s| [s.to_s, s.id.to_s] }] if future_sprints.any?
    grouped_sprints << [l('label_agile_sprint_list_active'), active_sprints.map { |s| [s.to_s, s.id.to_s] }] if active_sprints.any?
    grouped_sprints << [l('label_agile_sprint_list_old'), old_sprints.map { |s| [s.to_s, s.id.to_s] }] if old_sprints.any?
    grouped_sprints
  end

  def sprint_status_values_for_select
    AgileSprint.statuses.map { |status, value| [l("label_agile_sprint_status_#{status}"), value] }
  end

  def sprint_sharing_values_for_select
    AgileSprint.sharings.map { |share, value| [l("label_agile_sprint_sharing_#{share}"), value] }
  end

  def duration_values_for_select
    [[l(:label_agile_sprint_duration_select), nil]] +
      (1..4).map { |week| [l("label_agile_sprint_duration_week_#{week}"), week] }
  end
end