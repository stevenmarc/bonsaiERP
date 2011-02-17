class PaymentsController < ApplicationController
  # GET /payments
  # GET /payments.xml
  def index
    @payments = Payment.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @payments }
    end
  end

  # GET /payments/1
  # GET /payments/1.xml
  def show
    @payment = Payment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @payment }
    end
  end

  # GET /payments/new
  # GET /payments/new.xml
  def new
    session[:payment] = {}
    #begin
    transaction = Transaction.find_by_type_and_id( params[:type], params[:id] )
    session[:payment][:transaction_id] = transaction.id
    @payment = transaction.new_payment
    #rescue
      #redirect_to request.referer
    #end
  end


  # POST /payments
  # POST /payments.xml
  def create
    @payment = Payment.new(params[:payment])
    if params[:payment][:transaction_id].to_i == session[:payment][:transaction_id]
      if @payment.save
        redirect_ajax @payment
      else
        render :action => "new"
      end
    else
      render :text => "Hacking attemp!"
      #TODO Log error and recognize a Hacking attack
    end
  end

  # PUT /payments/:id/null_payment
  def null_payment
    @payment = Payment.find(params[:id])
    @payment.null_payment
    redirect_ajax @payment
  end

end