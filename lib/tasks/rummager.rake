namespace :rummager do
  desc "Add all published documents to the search index without removing them all first"
  task :index => ['rummager:index:detailed', 'rummager:index:government']

  task :warn_about_no_op do
    if Rails.env.development? && ENV["RUMMAGER_HOST"].blank?
      puts "Note: not actually submitting content to Rummager. Set RUMMAGER_HOST if you want to do so."
    end
  end

  namespace :index do
    desc "indexes only government documents"
    task :government => [:environment, :warn_about_no_op] do
      # TODO: re-implement with RummagerClient
    end

    desc "indexes only detailed guidance documents"
    task :detailed => [:environment, :warn_about_no_op] do
      # TODO: re-implement with RummagerClient
    end
  end

  desc "Remove all documents from the search index and then add all published documents"
  task :reset => ['rummager:reset:detailed', 'rummager:reset:government']

  namespace :reset do
    task :government => [:environment, :warn_about_no_op] do
      # TODO: re-implement with RummagerClient
      Rake::Task["rummager:index:government"].invoke
    end

    task :detailed => [:environment, :warn_about_no_op] do
      # TODO: re-implement with RummagerClient
      Rake::Task["rummager:index:detailed"].invoke
    end
  end
end
