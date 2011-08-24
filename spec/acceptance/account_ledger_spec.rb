# encoding: utf-8
# author: Boris Barroso
# email: boriscyber@gmail.com
require File.dirname(__FILE__) + '/acceptance_helper'

feature "Test account ledger", "for in outs and transferences" do
  background do
    OrganisationSession.set(:id => 1, :name => 'ecuanime', :currency_id => 1)
    UserSession.current_user = User.new {|u| u.id = 1}

    create_currencies
    create_account_types
    b = create_bank(:currency_id => 1, :name => "Bank chiquito")
    @bank_account = b.account
    @bank_ac_ic = b.account.id
    @client = create_client(:matchcode => "Lucas Estrella")

    @params = {
      :date => Date.today, :operation => "in", :reference => "For more", :amount => 100,
      :account_id => @bank_ac_ic, :contact_id => @client.id
    }
  end

  scenario "It should correctly assing the correct methods for money" do

    al = AccountLedger.new_money(:operation => "in", :account_id => 1)

    ac = @client.accounts.first

    al.to_id.should == nil
    al.in?.should == true
    al.account.currency_symbol.should == "Bs."
    al.active.should == true

    al = AccountLedger.new_money(:operation => "in", :account_id => @bank_ac_ic, :contact_id => @client.id, :amount => 100, :reference => "Check 1120012" )
    al.save.should == true

    al.active.should == true

    #al.description.should == "Ingreso por #{al.to}"
    al.creator_id.should == 1

    al.currency_id.should == 1
    al.amount.should == 100
    al.conciliation.should == false

    al.account.original_type.should == "Bank"
    al.to_id.should == ac.id
    al.to.original_type.should == "Client"

    #det1 = al.account_ledger_details[0]
    #det2 = al.account_ledger_details[1]

    #det1.account_id.should == @bank_ac_ic
    #det1.amount.should == 100
    #det1.currency_id.should == 1
    #det1.exchange_rate.should == 1
    #det1.account.amount.should == 0

    #det2.account_id.should == @cli_ac_id
    #det2.amount.should == -100
    #det2.currency_id.should == 1
    #det2.exchange_rate.should == 1
    #det2.account.amount.should == 0
    #det2.account.cur(1).amount.should == 0

    UserSession.current_user = User.new{|u| u.id= 2}

    al.conciliate_account

    al.conciliation.should == true
    al.reload

    al.approver_id.should == 2
    al.approver_datetime.kind_of?(Time).should == true

    al.account.amount.should == 100
    al.to.amount.should == -100

    #det1.account_id.should == @bank_ac_ic
    #det1.amount.should == 100
    #det1.currency_id.should == 1
    #det1.exchange_rate.should == 1
    #det1.account.amount.should == 100
    #det1.account.cur(1).amount.should == 100

    #det2.account_id.should == @cli_ac_id
    #det2.amount.should == -100
    #det2.currency_id.should == 1
    #det2.exchange_rate.should == 1
    #det2.account.amount.should == -100
    #det2.account.cur(1).amount.should == -100
  end

  scenario "It should create amount between two different currencies" do
    b = create_bank(:currency_id => 2)
    b.account.currency_id.should == 2

    al = AccountLedger.new_money(:operation => "in", :account_id => b.account.id, :contact_id => @client.id, :amount => 100, :reference => "Check 1120012" )
    al.save.should == true

    al.reload
    al.to.original_type.should == "Client"
    @client.reload
    @client.accounts.size.should == 2

    al.account.amount.should == 0
    al.to.amount.should == 0

    al.conciliate_account.should be_true
    al.reload

    al.account.amount.should == 100
    al.to.amount.should == -100
  end

  scenario "It should create an out" do
    al = AccountLedger.new_money(:operation => "out", :account_id => @bank_ac_ic,              
           :contact_id => @client.id, :amount => 100, :reference => "Check 1120012" )
    

    al.save.should == true
    al.organisation_id.should == 1
    al.amount.should == -100
    al.operation.should == "out"

    al.account.amount == 0
    al.to.amount == 0

    al.conciliate_account.should == true
    al.reload

    al.account.amount == -100
    al.to.amount == -100
  end

  scenario "Nulling an account" do
    al = AccountLedger.new_money(@params)

    al.save.should == true
    al.active.should == true

    UserSession.current_user = User.new{|u| u.id= 5}

    al.null_transaction.should == true
    al.nuller_id.should == 5
    al.nuller_datetime.kind_of?(Time).should == true

    al.active.should == false
    al.reload

    al.account.amount.should == 0
    al.to.amount.should == 0

    al.conciliate_account.should == false
  end

  scenario "Make a transference" do
    c = Cash.create!(:name => 'Cash 1', :currency_id => 2)
    c_ac_id = c.account.id
    @params[:operation] = 'trans'
    @params[:to_id] = c_ac_id
    @params[:exchange_rate] = 0.5

    al = AccountLedger.new_money(@params)

    al.save.should == true
    al.active.should == true

    ac1 = al.account
    ac2 = al.to

    ac1_amt = ac1.amount
    ac2_amt = ac2.amount

    al.conciliate_account.should == true

    ac1.reload.amount.should == ac1_amt - 100
    ac2.reload.amount.should == ac2_amt + 50

  end
end
