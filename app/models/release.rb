class Release < ApplicationRecord
  has_many :tracks
  belongs_to :release_group
end