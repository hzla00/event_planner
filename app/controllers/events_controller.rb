class EventsController < ApplicationController

	include SessionsHelper

	before_filter :get_event, only: [:activate, :route, :generate_poll, :show]

	def create
		@event = Event.create params[:event]
		@event.update_times
		@event.assign_user_and_create_first_poll current_user
		redirect_to opentable_path(event_id: @event.id)
	end

	def booking_info
		@event = Event.new
	end

	def activate
		@event.update_attributes status: "activated"
		render nothing: true
	end

	def route
		session[:user_id] = nil
		if params[:code] != @event.routing_url.split("?code=").last
			redirect_to root_path and return
		end
		@polls = @event.polls
		session[:route_poll] = true
		session[:event_id] = @event.id
	end

	def generate_poll
		if @event.user_id == current_user.id
			poll = event.polls.where(user_id: current_user.id).first
			redirect_to poll.url and return
		else
			poll = Poll.create event_id: @event.id, confirmed_attending: true ,email: current_user.email, user_id: current_user.id
			poll.choices << @event.choices
			@event.users << current_user
			redirect_to poll.url
		end
	end

	def show
		@poll = @event.polls.where(user_id: current_user.id).first
		@service = Service.find @event.service_id
		@choices = @event.choices
	end

	private

	def get_event
		@event = Event.find(params[:id])
	end
end
