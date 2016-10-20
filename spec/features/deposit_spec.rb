require 'rails_helper'

RSpec.describe DepositController, :type => :feature do

  describe "index", :js => true do
    before do
      visit deposit_path
    end

    it "renders title" do
      expect(page).to have_content "Academic Commons Self-Deposit"
    end

    it "contains a Start Here button" do
      expect(page).to have_button("Start Here")
    end

    it "does not display the user agreement" do
      expect(page).not_to have_content "Read and Accept Author Agreement"
    end

    context "after clicking Start Here" do
      before do
        click_button "Start Here"
      end

      it "cannot continue until user has agreed" do
        click_button "Continue"
        expect(page).to have_content "You must accept the Author Rights Agreement to continue."
        expect(page).to have_content "Step 1 of 3"
      end

      context "once user has agreed" do
        before do
          check "acceptedAgreement"
          click_button "Continue"
        end

        it "renders next page" do
          expect(page).to have_content "Required Information"
          expect(page).to have_content "Step 2 of 3"
        end

        it 'cannot continue until all required information is entered' do
          click_button "Continue"
          expect(page).to have_content "Please enter the title."
          expect(page).to have_content "Step 2 of 3"
        end

        context "once deposit information is entered" do
          before do
            fill_in("name", :with => "John Doe")
            fill_in("email", :with => "xyz123@columbia.edu")
            attach_file("file", File.join(Rails.root, "spec/fixtures/test_file.txt"))
            fill_in("title", :with => "Test Deposit")
            fill_in("author", :with => "John Doe")
            fill_in("abstr", :with => "Blah Blah Blah")
            click_button "Continue"
          end

          it "renders information to review" do
            expect(page).to have_content "Review and Submit"
          end

          context "when user submits" do
            before do
              click_button "Submit"
            end

            after do
              FileUtils.rm(File.join(Rails.root, Deposit.first.file_path)) # Remove file deposited
            end

            it 'renders submission confirmation' do
              expect(page).to have_content "We Have Received Your Submission"
            end

            it "creates deposit record" do
              expect(Deposit.count).to eq 1
            end
          end
        end
      end
    end
  end
end
