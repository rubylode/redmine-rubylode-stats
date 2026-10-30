# Rubylode Stats: charts over a project's tickets, for Redmine
# Copyright (C) 2026  Nick Gorbikoff
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software

# Demo data for trying the charts: two projects, four people, about 150 tickets over the last 12 weeks.
# Sample data only, every name is invented. It touches nothing but the two demo projects, the demo role and the four demo users.
#
#   docker exec redmine-stats-dev bundle exec rails runner plugins/redmine_rubylode_stats/script/seed_demo.rb
#
# Safe to run twice: a demo project that already has tickets is left as it is.
# The four demo users sign in with their login and the password below. The administrator stays admin / admin.
# On a Redmine without the default data (no trackers, statuses or priorities) the script loads Redmine's English defaults.

DEMO_PASSWORD = "demo-password-1".freeze
WEEKS_OF_HISTORY = 12
TICKETS_PER_PROJECT = 75
CLOSED_SHARE = 0.7
REOPENED_TICKETS_PER_PROJECT = 3
CLOSED_WITHOUT_JOURNAL_PER_PROJECT = 3
WITHOUT_CATEGORY_PER_PROJECT = 4
WITHOUT_ASSIGNEE_PER_PROJECT = 4

DEMO_USERS = [
  { login: "ava.fern", firstname: "Ava", lastname: "Fern" },
  { login: "ben.marsh", firstname: "Ben", lastname: "Marsh" },
  { login: "cora.lane", firstname: "Cora", lastname: "Lane" },
  { login: "dev.reed", firstname: "Dev", lastname: "Reed" }
].freeze

DEMO_PROJECTS = [
  {
    name: "Demo Garden", identifier: "demo-garden",
    categories: %w[Soil Seeds Irrigation Tools],
    versions: ["Spring planting", "Summer harvest"],
    actions: ["Turn over", "Order", "Label", "Repair", "Test", "Measure", "Plan", "Clean", "Prune", "Move"],
    things: ["the compost bins", "tomato seedlings", "drip lines", "the shed shelves", "raised bed four", "the rain barrel",
             "pepper trays", "the hose reels", "mulch delivery", "the greenhouse vents", "garden gloves", "the fence gate"]
  },
  {
    name: "Demo Workshop", identifier: "demo-workshop",
    categories: %w[Woodwork Metalwork Electrical Safety],
    versions: ["Bench build", "Tool upgrade"],
    actions: ["Sand", "Order", "Calibrate", "Sharpen", "Inspect", "Cut", "Wire", "Label", "Replace", "Sort"],
    things: ["the workbench top", "clamp rack", "the band saw blade", "dust extraction", "drill press table", "shop lights",
             "the lathe chuck", "fire extinguisher tags", "bolt bins", "the router fence", "extension cords", "the grinder guard"]
  }
].freeze

def random_generator
  @random_generator ||= Random.new(2026)
end

def pick(list)
  list[random_generator.rand(list.size)]
end

# Weekends get few tickets: a Saturday or Sunday moves to the nearest weekday nine times in ten.
def weekday_biased(time)
  return time unless time.saturday? || time.sunday?
  return time if random_generator.rand < 0.1
  time.saturday? ? time - 1.day : time + 1.day
end

def working_hours_time(day_offset, now)
  base = (now - day_offset.days).beginning_of_day + random_generator.rand(8..17).hours + random_generator.rand(60).minutes
  [weekday_biased(base), now - 30.minutes].min
end

def ensure_default_data
  return if Tracker.exists? && IssueStatus.exists? && IssuePriority.exists?
  Redmine::DefaultData::Loader.load("en")
  puts "Loaded Redmine's default trackers, statuses, priorities and roles."
end

def ensure_role
  role = Role.find_or_initialize_by(name: "Demo member")
  role.assignable = true
  role.issues_visibility = "all"
  role.permissions = %i[view_issues add_issues edit_issues add_issue_notes view_rubylode_stats]
  role.save!
  role
end

def ensure_users
  DEMO_USERS.map do |attributes|
    User.find_by(login: attributes[:login]) || User.new(attributes).tap do |user|
      user.mail = "#{attributes[:login]}@example.com"
      user.password = user.password_confirmation = DEMO_PASSWORD
      user.must_change_passwd = false
      user.language = "en"
      user.save!
    end
  end
end

def ensure_project(definition, users, role)
  project = Project.find_by(identifier: definition[:identifier]) || Project.new(name: definition[:name], identifier: definition[:identifier])
  project.is_public = false
  project.trackers = Tracker.all
  project.enabled_module_names = (Setting.default_projects_modules + %w[issue_tracking rubylode_stats]).uniq
  project.save!
  users.each do |user|
    Member.create!(project: project, user: user, roles: [role]) unless project.members.exists?(user_id: user.id)
  end
  definition[:categories].each do |name|
    IssueCategory.find_or_create_by!(project: project, name: name)
  end
  definition[:versions].each_with_index do |name, index|
    Version.find_or_create_by!(project: project, name: name) do |version|
      version.status = "open"
      version.effective_date = Date.current + (index + 1) * 5 * 7
    end
  end
  project
end

def closing_journal(issue, user, time, old_status, new_status)
  journal = Journal.new(journalized: issue, user: user)
  journal.details << JournalDetail.new(property: "attr", prop_key: "status_id", old_value: old_status.id.to_s, value: new_status.id.to_s)
  journal.save!
  journal.update_columns(created_on: time)
end

def seed_tickets(project, definition, users, now)
  trackers = Tracker.sorted.to_a
  priorities = IssuePriority.all.to_a
  weighted_priorities = priorities + priorities.select { |priority| priority.name == "Normal" } * 3
  statuses = IssueStatus.all.index_by(&:name)
  open_statuses = statuses.values_at("New", "In Progress", "Feedback").compact
  closed_statuses = [statuses["Closed"]] * 6 + [statuses["Rejected"]]
  categories = project.issue_categories.to_a
  versions = project.versions.to_a
  total_days = WEEKS_OF_HISTORY * 7
  closed_count = (TICKETS_PER_PROJECT * CLOSED_SHARE).round

  tickets = Array.new(TICKETS_PER_PROJECT) { |index| { closed: index < closed_count, index: index } }
  tickets.shuffle!(random: random_generator)
  closed_tickets = tickets.select { |ticket| ticket[:closed] }
  closed_tickets.first(REOPENED_TICKETS_PER_PROJECT).each { |ticket| ticket[:reopened] = true }
  closed_tickets.last(CLOSED_WITHOUT_JOURNAL_PER_PROJECT).each { |ticket| ticket[:without_journal] = true }
  tickets.first(WITHOUT_CATEGORY_PER_PROJECT).each { |ticket| ticket[:without_category] = true }
  tickets.last(WITHOUT_ASSIGNEE_PER_PROJECT).each { |ticket| ticket[:without_assignee] = true }

  tickets.each do |ticket|
    if ticket[:closed]
      # More tickets close in the recent weeks than in the early ones.
      closed_at = working_hours_time(total_days * random_generator.rand**1.7, now)
      days_open = 0.2 + random_generator.rand**2 * 24
      created_at = [closed_at - days_open.days, now - total_days.days].max
      created_at = [created_at, closed_at - 2.hours].min
      created_at = [created_at, now - total_days.days].max
    else
      created_at = working_hours_time(total_days * random_generator.rand**0.9, now)
      closed_at = nil
    end

    author = pick(users)
    issue = Issue.new(
      project: project, tracker: pick(trackers), author: author, priority: pick(weighted_priorities),
      subject: "#{pick(definition[:actions])} #{pick(definition[:things])}",
      category: (pick(categories) unless ticket[:without_category]),
      fixed_version: (pick(versions) if random_generator.rand < 0.8),
      assigned_to: (pick(users) unless ticket[:without_assignee])
    )
    issue.status = ticket[:closed] ? statuses["New"] : pick(open_statuses)
    issue.save!
    # A reloaded copy: update_columns on the object that was just saved changes no row.
    issue = Issue.find(issue.id)
    issue.update_columns(created_on: created_at, updated_on: created_at, start_date: created_at.to_date)

    next unless ticket[:closed]
    final_status = pick(closed_statuses)
    previous_status = random_generator.rand < 0.5 ? statuses["New"] : statuses["In Progress"]
    final_closer = ticket[:without_assignee] ? pick(users) : [issue.assigned_to, issue.assigned_to, pick(users)].sample(random: random_generator)

    if ticket[:without_journal]
      issue.update_columns(status_id: final_status.id, closed_on: closed_at, updated_on: closed_at, done_ratio: 100)
    elsif ticket[:reopened]
      first_close = created_at + (closed_at - created_at) * 0.4
      reopened_at = created_at + (closed_at - created_at) * 0.7
      closing_journal(issue, pick(users), first_close, previous_status, statuses["Closed"])
      closing_journal(issue, pick(users), reopened_at, statuses["Closed"], statuses["In Progress"])
      closing_journal(issue, final_closer, closed_at, statuses["In Progress"], final_status)
      issue.update_columns(status_id: final_status.id, closed_on: closed_at, updated_on: closed_at, done_ratio: 100)
    else
      closing_journal(issue, final_closer, closed_at, previous_status, final_status)
      issue.update_columns(status_id: final_status.id, closed_on: closed_at, updated_on: closed_at, done_ratio: 100)
    end
  end
end

User.current = User.find_by!(login: "admin")
now = Time.current
Mailer.with_deliveries(false) do
  ensure_default_data
  role = ensure_role
  users = ensure_users
  DEMO_PROJECTS.each do |definition|
    project = ensure_project(definition, users, role)
    if project.issues.exists?
      puts "#{project.name}: already has tickets, left as it is."
    else
      seed_tickets(project, definition, users, now)
    end
  end
end

demo_projects = Project.where(identifier: DEMO_PROJECTS.map { |definition| definition[:identifier] })
puts "Demo projects: #{demo_projects.map(&:name).join(', ')}"
puts "Demo users: #{DEMO_USERS.map { |attributes| attributes[:login] }.join(', ')} (password #{DEMO_PASSWORD})"
demo_projects.each do |project|
  closed_count = project.issues.joins(:status).where(issue_statuses: { is_closed: true }).count
  puts "#{project.name}: #{project.issues.count} tickets, #{closed_count} closed, " \
       "#{project.issue_categories.count} categories, #{project.versions.count} versions, " \
       "#{project.issues.where(category_id: nil).count} without category, #{project.issues.where(assigned_to_id: nil).count} without assignee, " \
       "#{Journal.joins(:details).where(journalized_type: 'Issue', journalized_id: project.issues.select(:id), journal_details: { prop_key: 'status_id' }).count} status changes"
end
