class AgileSprintsController < ApplicationController
  helper :agile_sprints
  include AgileSprintsHelper

  before_action :find_optional_project, only: [:new, :create, :edit, :update, :destroy]
  before_action :find_agile_sprint, only: [:edit, :update, :destroy]

  def new
    @agile_sprint = @project.agile_sprints.build(initial_agile_sprint_params)
  end

  def create
    @agile_sprint = @project.agile_sprints.build
    attrs = params[:agile_sprint]
    attrs = attrs.to_unsafe_hash if attrs.respond_to?(:to_unsafe_hash)
    @agile_sprint.safe_attributes = attrs

    if @agile_sprint.save
      flash[:notice] = l(:notice_successful_create)
      respond_to do |format|
        format.html { redirect_to_settings_in_projects }
        format.api  { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render action: 'new' }
        format.api  { render_validation_errors(@agile_sprint) }
      end
    end
  end

  def edit
  end

  def update
    attrs = params[:agile_sprint]
    attrs = attrs.to_unsafe_hash if attrs.respond_to?(:to_unsafe_hash)
    @agile_sprint.safe_attributes = attrs

    if @agile_sprint.save
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to_settings_in_projects }
        format.api  { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render action: 'edit' }
        format.api  { render_validation_errors(@agile_sprint) }
      end
    end
  end

  def destroy
    @agile_sprint.destroy
    respond_to do |format|
      format.html { redirect_to_settings_in_projects }
      format.api  { render_api_ok }
    end
  end

  private

  def initial_agile_sprint_params
    last_sprint = @project.agile_sprints.last
    {
      name: last_sprint ? last_sprint.name.gsub(/(\d+)/) { $&.to_i + 1 } : '',
      start_date: workday_for(Date.today)
    }
  end

  def workday_for(date)
    return date + 1 if date.instance_eval { sunday? }
    return date + 2 if date.instance_eval { saturday? }
    date
  end

  def find_agile_sprint
    @agile_sprint = @project.agile_sprints.where(id: params[:id]).first
    return render_404 unless @agile_sprint
  end

  def redirect_to_settings_in_projects
    redirect_back_or_default settings_project_path(@project, tab: 'agile_sprints')
  end
end