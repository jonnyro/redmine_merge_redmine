require File.dirname(__FILE__) + '/../test_helper'

class SourceProjectTest < ActiveSupport::TestCase
  context "#migrate" do
    setup do
      User.anonymous # preload
      User.generate_with_protected!(:login => 'admin', :mail => 'admin@somenet.foo')
      User.generate_with_protected!(:login => 'jsmith', :mail => 'jsmith@somenet.foo')

      Project.generate!(:name => 'eCookbook')
      Project.generate!(:identifier => 'onlinestore')
    end
    
    should_add_each_record_from_the_source_to_the_destination(Project, 4) { SourceProject.migrate }

    should "skip projects that already exist in the destination, based on name" do
      SourceProject.migrate

      assert_equal 1, Project.count(:conditions => {:name => 'eCookbook'})
    end
    
    should "skip projects that already exist in the destination, based on identifier" do
      SourceProject.migrate

      assert_equal 1, Project.count(:conditions => {:identifier => 'onlinestore'})
    end

    should "enable the modules for each project" do
      SourceProject.migrate

      project = Project.find_by_identifier('subproject1')

      assert project
      assert_equal 4, project.enabled_modules.length
      assert project.enabled_modules.collect(&:name).include?('repository')
      assert project.enabled_modules.collect(&:name).include?('wiki')
      assert project.enabled_modules.collect(&:name).include?('time_tracking')
      assert project.enabled_modules.collect(&:name).include?('issue_tracking')
    end

    should "add the project's trackers" do
      SourceTracker.migrate
      SourceProject.migrate

      project = Project.find_by_identifier('subproject1')

      assert project
      assert_equal 3, project.trackers.length
      assert project.trackers.include?(Tracker.find_by_name('Feature request'))
      assert project.trackers.include?(Tracker.find_by_name('Support request'))
      assert project.trackers.include?(Tracker.find_by_name('Bug'))
    end

    should "keep the parent project association" do
      Project.find_by_name('eCookbook').destroy
      SourceProject.migrate

      project = Project.find_by_identifier('ecookbook')
      subproject = Project.find_by_identifier('subproject1')
      subproject2 = Project.find_by_identifier('private-child')
      sub_sub_project = Project.find_by_identifier('another')

      assert project
      assert subproject
      assert sub_sub_project
      assert_equal project, subproject.parent
      assert_equal project, subproject2.parent
      assert_equal subproject2, sub_sub_project.parent
    end
  end
end
