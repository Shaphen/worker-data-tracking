class WorkerBeesController < ApplicationController
  include PercentageAccepted

  def index
    @worker_bees = WorkerBee.all
    render :index
  end

  def show
    @comb_memberships = CombStaffMember.where(worker_id: params[:id]) # find all membershipts
    @active_membership = @comb_memberships.order(:created_at).last # find active membership (last assigned comb)

    # get worker bee info for display
    @worker_bee = WorkerBee.find_by(id: params[:id])
    @comb = Comb.find_by(id: @active_membership.comb_id)
    @supervisor = WorkerBee.find_by(id: @comb.supervisor_id)

    # data for charts and variable exchanges
    @data = DataEntry.where(worker_id: params[:id]) # grab all data of worker bee
    gon.worker_name = @worker_bee.name
    gon.dates, gon.pg_values, gon.nectars, @percent_accepted = [], [], [], []
    @curr_advisement = @data.first.advisement
    @accepted = 0.0
    @rejected = 1.0
    
    # iterate each entry in data table and push into exchange gem variable
    @data.order(:date).each do |entry|
      gon.dates << entry.date if gon.dates.length < 8
      gon.pg_values << entry.pollen_globs if gon.pg_values.length < 8
      gon.nectars << entry.nectar / 100 if gon.nectars.length < 8

      # starter variables for accepted percentage logic
      if entry.advisement
        @curr_advisement = entry.advisement 
        @accepted = 0
        @rejected = 0
      end

      # call helper method and reassign variables
      results = PercentageAccepted.calculate(entry.nectar, @curr_advisement, @accepted, @rejected)
      @percent_accepted.unshift(results[0].round()) # unshift because table goes from bottom-up (as per design docs)
      @accepted = results[1]
      @rejected = results[2]
    end

    render :show
  end
  
end
