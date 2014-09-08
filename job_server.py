import tornado
import tornado.ioloop
import tornado.web
import os, uuid

# setup config options
import config

from tornado.options import parse_command_line, parse_config_file

import job_manager

class SubmitJobForm(tornado.web.RequestHandler):
    def get(self):
        self.render("submit_job.html")

class JobOptionsModule(tornado.web.UIModule):

    def kill_url(self, job):
        return "kill/" + job.uuid

    def log_url(self, job):
        # TODO:  Make data dir based on options config
        return job.worker_url + "/data/" + job.uuid + ".log"

    def download_url(self, job):
        return job.primary_url + "/data/" + job.uuid + "/output.zip"

    def render(self, job):
        href_templ = "<a href=%s>%s</a>" 
        if job.status == job_manager.JobManager.STATUS_RUNNING:
           log_option = href_templ % (self.log_url(job), "Log")
           kill_option = href_templ % (self.kill_url(job), "Kill")
           return "%s,%s" % (log_option, kill_option)

        if job.status == job_manager.JobManager.STATUS_COMPLETE:
           log_option = href_templ % (self.log_url(job), "Log")
           dload_option = href_templ % (self.download_url(job), "Download")
           return "%s,%s" % (log_option, dload_option)

        return ""
        
class JobHandler(tornado.web.RequestHandler):

    def initialize(self, job_mgr):
        self.job_mgr = job_mgr

    """
    Store the input file and queue the job

    TODO:  
    - Allow URL based job input
    - Handle exceptions
    """
    def post(self):
        model = self.get_argument('model')
        job_name = self.get_argument('job_name')
        file_info = self.request.files['zip_file'][0]
        file_name = file_info['filename']
        
        # create new job
        job = job_manager.Job(model)
        job.name = job_name
        self.job_mgr.enqueue(job, file_info['body'])
        self.finish("job %s is queued to be run" % job.uuid)

    """
    Get the list of jobs
    """
    def get(self):
        jobs =  self.job_mgr.get_jobs()
        # order descending
        jobs.sort(key=lambda job: job.created, reverse=True)
        self.render("view_jobs.html", jobs=jobs)
       
if __name__ == "__main__":

    parse_command_line()
    parse_config_file("config.ini")

    # get the command_ keys
    command_dict = config.options.group_dict("model_command")

    jm = job_manager.JobManager(config.options.redis_url, 
                                config.options.primary_url, 
                                config.options.worker_url,
                                config.options.data_dir,
                                command_dict)


    application = tornado.web.Application([
            (r"/jobs/submit", SubmitJobForm),
            (r"/jobs", JobHandler, dict(job_mgr=jm)),
            ], 
            template_path=os.path.join(os.path.dirname(__file__), "templates"),
            debug=config.options.debug, 
            ui_modules={'JobOptions': JobOptionsModule}
            )

    application.listen(config.options.port)

    # TODO:  Setup JobManager with config options and command_dict
    tornado.ioloop.IOLoop.instance().start()