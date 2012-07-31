module TutorProjectsHelper
  def unmarked_project_tasks(tutor_project_template, tutor)
    tutors_teams    = Team.where(:project_template_id => tutor_project_template.id, :user_id => tutor.id)
    tutors_projects = Project.includes(:tasks).find(
      TeamMembership.where(:team_id => [tutors_teams.map{|team| team.id}])
      .map{|membership| membership.project_id }
    )

    tutors_projects.map{|project| project.tasks }.flatten.select{|task| task.awaiting_signoff? }
  end

  def unmarked_tasks(tutors_projects)
    tutors_projects.map{|project| project.tasks }.flatten.select{|task| task.awaiting_signoff? }
  end

  def tasks_progress_bar(project, student)
    tasks = project.tasks

    progress = project.relative_progress

    raw(
      tasks.each_with_index.map{|task, i|
          task_class  = task.complete? ? progress.to_s.gsub("_", "-") : "incomplete-task"
          href        = "/tutor/projects/#{project.id}/students/#{student.id}/tasks/#{task.id}"

          "<a class=\"task-progress-item progress-#{task_class}\" href=\"#{href}\">#{i + 1}</a>"
        }.join("\n")
    )
  end
end