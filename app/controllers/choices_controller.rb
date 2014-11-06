class ChoicesController < ApplicationController
	
	include SessionsHelper
	before_filter :check_event_ownership

	def create
		images = params[:image_url_list].split("<OPTION>")
		titles = params[:title_list].split("<OPTION>")
		infos = params[:info_list].split("<OPTION>")
		service_ids = params[:id_list].split("<OPTION>")
		p params
		binding.pry
		event = Event.find(@event_id)
		polls = event.polls
		polls.each do |poll|
			poll.choices.destroy_all
			(0..(images.length - 1)).each do |i|
				Choice.create poll_id: poll.id, image_url: images[i], value: titles[i], add_info: infos[i], service_id: service_ids[i]
			end
		end
		redirect_to event_path(@event_id)	
	end

	def vote
		@choice = Choice.find params[:id]
		@event = @choice.poll.event
		answer = params[:answer]
		if answer == "yes"
			@choice.update_attributes yes: true
		else
			@choice.update_attributes yes: false
		end
		poll = @choice.poll
		if @choice.poll.choices.where(yes: nil).empty?
			poll.update_attributes answered: true
		end
		if @choice.yes_count >= @event.threshold && @event.confirmation_id == nil || (@choice.yes_count >= @event.threshold && @event.confirmation_id != nil && @event.current_choice != @choice.value) 
			ReservationWorker.perform_async({restaurant_id: 105223, date_time: '11/13/2014 21:30:00',
			party_size: @event.polls.count , first_name: @event.user.first_name, last_name: @event.user.last_name, 
			email: @event.user.email, phone_number: "9499813668"}, @event.user.id, @event.id, @choice.id)
		end
		render nothing: true
	end

	private


	def check_event_ownership
		if params[:event_id]
			event = Event.find params[:event_id]
			if event.user_id != session[:user_id]
				redirect_to dashboard_path
			else
				@event_id = params[:event_id]
			end
		end
	end
end
