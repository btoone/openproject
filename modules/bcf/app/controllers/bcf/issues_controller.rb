#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

module ::Bcf
  class IssuesController < BaseController
    include PaginationHelper

    before_action :find_project_by_project_id
    before_action :authorize

    before_action :check_file_param, only: %i[prepare_import]
    before_action :get_persisted_file, only: %i[perform_import]
    before_action :persist_file, only: %i[prepare_import]

    before_action :build_importer, only: %i[prepare_import perform_import]

    before_action :get_issue_type

    menu_item :bcf

    def index
      @issues = ::Bcf::Issue.in_project(@project)
                            .with_markup
                            .includes(:comments, :work_package, viewpoints: :attachments)
                            .page(page_param)
                            .per_page(per_page_param)
    end

    def import; end

    def prepare_import
      @bcf_file = params[:bcf_file]

      begin
        @roles = Role.find_all_givable

        @listing = @importer.get_extractor_list! @bcf_file.path
        if @listing.blank?
          raise(StandardError.new(I18n.t('bcf.exceptions.file_invalid')))
        end

        @issues = ::Bcf::Issue.with_markup
                    .includes(work_package: %i[status priority assigned_to])
                    .where(uuid: @listing.map { |e| e[:uuid] })

        all_people = @listing.map { |entry| entry[:people] }.flatten.uniq
        all_mails = @listing.map { |entry| entry[:mail_addresses] }.flatten.uniq

        @known_users = User.where(mail: all_mails).includes(:memberships)
        @unknown_mails = all_mails.map(&:downcase) - @known_users.map(&:mail).map(&:downcase)
        @members = @known_users.select { |user| user.projects.map(&:id).include? @project.id }
        @non_members = @known_users - @members
        @invalid_people = all_people - all_mails
      rescue StandardError => e
        flash[:error] = I18n.t('bcf.bcf_xml.import_failed', error: e.message)
        redirect_to action: :index
      end
    end

    def perform_import
      begin
        result = @importer.import! @bcf_attachment.local_path
        flash[:notice] = I18n.t('bcf.bcf_xml.import_successful', count: result)
      rescue StandardError => e
        flash[:error] = I18n.t('bcf.bcf_xml.import_failed', error: e.message)
      end

      @bcf_attachment.destroy
      redirect_to action: :index
    end

    private

    def build_importer
      @importer = ::OpenProject::Bcf::BcfXml::Importer.new @project, current_user: current_user
    end

    def get_issue_type
      @issue_type = @project.types.find_by(name: 'Issue [BCF]')
    end

    def get_persisted_file
      @bcf_attachment = Attachment.find_by! id: session[:bcf_file_id], author: current_user
    rescue ActiveRecord::RecordNotFound
      render_404 'BCF file not found'
    end

    def persist_file
      file = params[:bcf_file]
      @bcf_attachment = Attachment.create! file: file, description: file.original_filename, author: current_user
      session[:bcf_file_id] = @bcf_attachment.id
    rescue StandardError => e
      flash[:error] = "Failed to persist BCF file: #{e.message}"
      redirect_to action: :index
    end

    def check_file_param
      path = params[:bcf_file]&.path
      unless path && File.readable?(path)
        flash[:error] = I18n.t('bcf.bcf_xml.import_failed', error: 'File missing or not readable')
        redirect_to action: :import
      end
    end
  end
end
