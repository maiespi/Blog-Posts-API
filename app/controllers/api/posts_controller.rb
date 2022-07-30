# frozen_string_literal: true
require 'json'

module Api
  # Posts controller
  class PostsController < ApplicationController
    def index
      # variables for search queries
      authorIds = params[:authorIds] ? params[:authorIds].split(',') : []

      sortBy = params[:sortBy] ? params[:sortBy] : 'id'
      acceptableSortBy = ["id", "reads", "likes", "popularity"]

      direction = params[:direction]
      acceptableDirections = ["asc", "desc"]

      response = []

      # error parsing
      if authorIds.length < 1
        render json: { "error": "<Author ID parameter is required>" }, status: 400 
        return
      end

      if (!acceptableSortBy.include?(sortBy) )
        render json: { "error": "<sortBy parameter is not valid>" }, status: 400
        return
      elsif (direction) && (!acceptableDirections.include?(direction) )
        render json: { "error": "<sortBy parameter is not valid>" }, status: 400
        return
      end

      for id in authorIds do
        result = Post.get_posts_by_user_id(id)
        response.push(result)
      end

      response = response.flatten(1).uniq

      if (direction == "desc")
        response = response.sort_by { |item| item[sortBy] }.reverse
      else
        response = response.sort_by { |item| item[sortBy] }
      end  

      render json: { "posts": response }, status: 200
      # should be response.flatten(1).uniq after posts

    end

    def create
      post = current_user.posts.create!(post_params)
      render json: { post: post }, status: :created
    end

    private

    def post_params
      params.permit(:text, :likes, :reads, :popularity, tags: [])
    end

  end
end
