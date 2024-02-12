# A quick and easy guide to using Caddy as a load balancer on Google Cloud Platform

!!! note
    **Editor's note**:
    
    I wrote this blog post at a very early point in my DevOps career. Although some of the technology is already outdated, the post itself is still thorough and useful - thus, I like keeping it in my professional portfolio.

*Originally authored in 2019*

When I was tinkering with deploying a Caddy container as a Load Balancer for an application container on GCP, I tripped over a few basic things that I think are probably pretty common confusions when you're just getting started. Most of the guides I found online didn't really consider some of these things, so, after successfully deploying this for myself, I figured I would write a quick-'n-easy guide about this in the hopes to help anyone else who's having trouble with this.

## Assumptions

In thinking about starting a blog that contains technical posts, one of the things I frequently think about is what pieces of context might be useful for my potential readers (including future versions of myself!), to determine whether or not the content will actually be useful to them and their case. So, as this will be my first published post containing such content, I'm going to start by outlining the assumptions the rest of this post makes.

This post is written with the assumption that you have some basic or working knowledge of both Kubernetes and of GCP [Google Cloud Platform](https://cloud.google.com/getting-started). It also assumes, for the sake of issue scoping, that you're trying to do the following in a running cluster on GCP. The same principles likely hold for EKS (AWS's managed Kubernetes platform), and for a self-hosted solution, you'll have to consider how this could map onto whatever you're using for your networking (this may be something like a network policy manager such as [Calico](https://www.projectcalico.org/calico-networking-for-kubernetes/) or [Flannel](https://github.com/coreos/flannel)).

Our **assumed environment** is therefore:

* A working application container...
* ...running in a working Kubernetes cluster...
* ...hosted on GCP.

We will also assume that the **end goal** is, given the above stated context:

* To create a working Caddy container image...
* ...built using Docker...
* ...functioning as a Load Balancer...
* ...with HTTPS enabled.

## About Caddy

!!! note
    This guide deals with Caddy V.1.

    [Caddy](https://caddyserver.com/v1/docs) is a lightweight Web server whose primary claim to fame is that it uses the [CertMagic](https://github.com/mholt/certmagic) library to handle [_automatic_ HTTPS](https://caddyserver.com/v1/docs/automatic-https) for your Web server. It's a really elegant solution to helping encrypt more of the Web, and is a favorite among DevOps engineers and system administrators for testing purposes when you want to make sure HTTPS will work. It's particularly nice that you can set up Caddy to get certificates from Let's Encrypt's [staging environment](https://letsencrypt.org/docs/staging-environment/), so that you can test a ton and not be limited by LE by accidentally throttling their servers.

So, how do we use this in Kubernetes, specifically, GCP, which has its own networking "gotchas" that need to be considered?

## Containers and Kubernetes

Let's start with the Caddy side of things. If you're at all familiar with the basics of Kubernetes, it'll probably be obvious what the first steps are in getting your Caddy container to work is to have the container to begin with. This means that first, we'll have to make ourselves a container from an image, ideally one that is customized for our purposes.

Caddy calls its configuration files `Caddyfiles`. In my case, I wanted to write a simple Caddyfile that would trigger the automatic HTTPS capability as well as act as a proxy for my actual Web container.

Caddy's [requirements for automatic HTTPS](https://caddyserver.com/v1/docs/automatic-https) are pretty simple:

1. The hostname:
     - is not empty
     - is not `localhost`
     - is not an IP address
     - has no more than 1 wildcard (`*`)
     - the wildcard is the left-most label
1. The port is not explicitly `80`
2. The scheme is not explicitly `http`
3. TLS is not turned off in site's definition
4. Certificates and keys are not provided by you
5. Caddy is able to bind to ports `80` and `443` (unless you use the DNS challenge)

So long as all of the above criteria are met, Caddy _should_ be able to automatically issue HTTPS certificates. These are all basically what you might expect to be true for the issuing of a TLS certificate.

In my case, my Caddyfile ended up looking like this:

```nginx
mydomain.site {
    proxy / myapp-web:80 {
        transparent
        websocket
    }
    log stdout
    errors stdout
}
```

A couple of things are somewhat interesting about this Caddyfile. For starters, you ought to notice that the domain name for the website, `mydomain.site`, is _not_ prepended with the `http` scheme. As we were told by Caddy, the scheme for our domain name must _not_ be explicitly `http` if we want to get automatic TLS. So, check.

Perhaps the more interesting thing, though, and the detail possibly more relevant to our specific situation, is the domain to which we are proxying. `myapp-web` is actually going to be the hostname from within the VPC, which the container is automatically assigned based on the labels of your Kubernetes manifest. Here, we explicitly define that the port for the service _to which_ we will be _proxying_ is `80`. Meanwhile, we've of course left off the port for our main host at the top.

Following our `proxy` line, we've got a `transparent` preset, which is actually just shorthand for [the more familiar proxy pass headers](https://caddyserver.com/v1/docs/proxy), as well as a `websocket` preset, which means we're telling Caddy to proxy forward WebSocket connections from our proxy.

Then we have some pretty clear lines telling us what's going to happen to our error and access logs (they'll be sent to standard out).

And that's really all there is to it! I think that's the magic of Caddy: its simplicity. The double-edged sword factor comes in only with the fact that Caddy is magicking away a lot of things, and you should probably know what those things are actually collapsing to (eg. the `transparent` preset). But if you're already comfortable with Web servers, then this is really a nice way of creating a simple, straightforward, and lightweight server.

In just a moment, we'll look at passing in our options for using the Let's Encrypt staging environment and running our process. (If you're wondering about Caddy's ability to use DNS challenges rather than HTTP challenges, you can read more about that [on Caddy's DNS Providers repo](https://github.com/caddyserver/dnsproviders).)

## Containerizing Caddy
Okay, so now that we've got what we presume to be a working Caddyfile, the next step in our process is to containerize that bad boy in order to make sure that our configuration works so that we have a base image to use for K8s.

My Dockerfile for the Caddy container (and image) looked like this:

```docker
FROM abiosoft/caddy

COPY Caddyfile /etc/Caddyfile

ENTRYPOINT ["/usr/bin/caddy"]
CMD ["--conf", "/etc/Caddyfile", "-ca", "https://acme-staging-v02.api.letsencrypt.org/directory"]
```

Again, lovely in its simplicity. Here, we base our container image on the original Caddy container, grabbing that Caddy source code for our ultimate process. Next, we copy the Caddyfile from our current working directory and put it into a reasonable location within the container's filesystem, `/etc/Caddyfile`. Then, we want to make sure that we run the Caddy process by placing its executable as our entrypoint, which is the thing that will be run as our primary process.

At last, we pass in the options to the process (Caddy) to configure it. The options we pass in here are:

* `--conf` - Letting the Caddy process know which configuration file we want it to use.
* `/etc/Caddyfile` - The path to the Caddyfile we want used.
* `-ca` - This is our option to Caddy where we'll define what CA (Certificate Authority) we want our server to use. This is absolutely necessary if we want to explicitly set the location for a testing CA, which, we do. 
* `https://acme-staging-v02.api.letsencrypt.org/directory` - Finally, the URL to the Let's Encrypt staging envrionment.

As [Caddy's docs](https://caddyserver.com/v1/docs/automatic-https) say:

!!! cite
    To test or experiment with your Caddy configuration, make sure you use the `-ca` flag to change the ACME endpoint to a staging or development URL, otherwise you are likely to hit rate limits, which can block your access to HTTPS for up to a week. This is especially common when using process managers or containers. Caddy's default CA is Let's Encrypt, which has a staging endpoint that is not subject to the same rate limits.

Let's take them up on that advice.

Finally, we've got to build our Docker image at the very least, and maybe run it locally if we want to test it out.

```docker
docker build -t myapp-caddy:testing .
```

I like to give my images clear names and tags for versioning, a basic best practice.

Once we've got all these pieces in play, it's time to move on to our clusters hosted on GCP; the really fun (and tricky) stuff.

## GCP

If you've never pushed a Docker image to GCR (that's the Google Container Registry), it's extremely easy to do so. You will have to first make sure you're logged in via `gcloud`; you can read more about that [on Google's docs](https://cloud.google.com/sdk/gcloud/reference/auth/login).

Once that's done, you'll want to grab the location of your image, either from the Google Cloud Web console or from `gcloud` on the command line using `gcloud container images list`.

If you don't yet have a repository, you'll want to choose one from the [list of available locations](https://cloud.google.com/container-registry/docs/overview), as well as the ID of your project, which are also visible by going to the Google Web console at the top of the page. Alternatively, you can always choose to host your images elsewhere; an AWS or other type of repository will work just as well, so long as you can get a public reference to its location.

In this case, let's say our repository hostname is `gcr.io`, and our project ID is `testing-123456`. What we need to do now is tag our image accordingly:

```docker
docker tag myapp-caddy:testing gcr.io/testing-123456/myapp-caddy:testing
```

You _can_ change the name of your container as well as its tags from their original settings, but why make it more complicated? Consistency is key, especially as we traverse contexts, platforms, and digital locations.

All right, next, let's push the tagged container to GCR:

```docker
docker push gcr.io/testing-123456/myapp-caddy:testing
```

We should be able to watch this happen, and it should not take long.

Once we've got our Caddy image pushed into our GCR repository, our next step is to configure the container to act as our load balancer. This is the trickiest step, and the step I stumbled on. I'll explain why in just a moment.

First and foremost, we have to do what should be relatively obvious: we have to create a manifest that will deploy our Caddy container.

My manifest looks like so:

```yaml
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: 'myapp-caddy-deployment'
  namespace: myapp
  labels:
    application: myapp-caddy-deployment
    branch: testing
    environment: testing
    type: load-balancer
spec:
  replicas: 1
  template:
    metadata:
      labels:
        application: 'myapp-caddy-deployment'
        branch: latest
    spec:
      containers:
        - name: 'myapp-caddy'
          image: gcr.io/testing-123456/myapp-caddy:testing
          ports:
            - containerPort: 80
            - containerPort: 443
          imagePullPolicy: Always
          resources:
            limits:
              memory: '64Mi'
              cpu: '100m'
            requests:
              memory: '64Mi'
              cpu: '100m'
```

As you can see, I'm setting my deployment container to be configured in the `testing` environment, and am basing my container on the `testing` Caddy image we just pushed.

But, and this is key: in order for our Caddy service to be reachable, we need to also deploy a service for it. Here's what my Caddy service looked like:

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-caddy-service
  namespace: myapp
  labels:
    application: myapp-caddy-deployment
    branch: testing
    environment: testing
    type: service
spec:
  selector:
    application: myapp-caddy-deployment
  type: LoadBalancer
  externalTrafficPolicy: "Local"
  loadBalancerIP: 76.12.243.14
  ports:
    - name: http
      protocol: "TCP"
      port: 80
    - name: https
      protocol: "TCP"
      port: 443
```

Okay, so, a couple of things should stand out to you right away. Firstly, that we've assigned a `type` of `LoadBalancer` to our service, which is what we want, because we want external traffic to be able to reach our in-VPC containers. But, wait, where did that `loadBalancerIP` come from? Ahh, now this is where we need to interact specifically with GCP's console.

I believe by far the easiest way to do this is from the Web console. On the GCP console, navigating to "VPC network" and then to "External IP addresses," you can reserve a static IP address on your VPC. This is necessary, over something like an Ingress, if you want to assign a DNS name to a service, which, we do, considering the fact we're going to be using TLS as well. (And besides, we want a domain name anyway!)

Clicking the "RESERVE STATIC ADDRESS" button leads you to a wizard, in which you can configure exactly what kind of address you'd like to create. It's extremely important to select the correct region in which your cluster exists, as well as your Network Service Tier. In the wrong region, you'll get an incorrect IP, and external load balancing was, at the time of this writing, only offered through the Premium Network Service Tier, so selecting anything else would/will not work. 

Once you have a static IP reserved, you can take it and plug it into your manifest, like the one above. And that's where the above IP came from! (Well, not really, I made that one up. I'm not handing out in-production IPs over here willy-nilly; but you get the idea.)

Once all of that is complete, you can go ahead and configure DNS for that service's IP and... voilà!

A couple really important concepts to remember: you're trying to make the CADDY container accessible via the outside world, so you need that container to have a SERVICE of its own. Why do I stress something that, to many of you, should be strikingly obvious? Well, let me tell you a story.

## We learn from our mistakes

Recently, on this exact task, I led myself astray without even realizing that I was doing so. And this issue isn't particularly specific to Caddy, per se, as much as it is relevant for system administrators who find themselves falling back on different/previous models of building infrastructure, particularly Web and network infrastructure.

Somehow momentarily forgetting the fact that I was on Kubernetes, I made the mistake of thinking, "okay, so I've got a load balancer, and I want it to proxy to my Web application container." What this thinking produced was the following mistake in my manifest for the Caddy container:

```yaml
spec:
  replicas: 1
  template:
    metadata:
      labels:
        application: 'myapp-web'
        branch: latest
[...]
    spec:
      containers:
        - name: 'myapp-web'
```

The particularly astute among you can probably see where I went wrong, already. To make matters even worse, when deploying the Service for my Caddy container, I made the following mistake, too:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-caddy-service
  namespace: myapp
  labels:
    application: myapp-web
    type: service
spec:
  selector:
    application: myapp-web
```

So, what's the main mistake here?

In thinking, "Oh, I have a load balancer that needs to proxy traffic to my Web application container, then the Caddy service should be pointing at the Web container."

I highlight this mistake because I think it's a really good example of more traditional sysadmin thinking muddying the waters for DevOps patterns. I was caught up thinking about the relationship between the reverse proxy server (and TLS terminator/generator) and the Web server, and not enough about the nature of the platform, or _how_ this relationship was being enacted. Further, I forgot where one process ended and another began. Another more experienced engineer on my team took a look at my broken config, and we worked on this for hours, both locked in tunnel vision, without seeing the problem.

It was finally only when a third engineer took a look at the work and immediately recognized what was wrong. It was kind of embarrassing to make such an obvious mistake, but as one of my mentors frequently says, "obvious things are hard to see."

At the end of the day, my Caddy container _had no Services_ with which to expose the Caddy container to the outside world, so when I was trying to hit the Service, of course I got only an "Unable to connect" error in my browser.

So, of course, once I appropriately configured a service (`LoadBalancer`) for the Caddy container itself, then the Caddy container did its thing within the VPC, reverse proxying traffic to our Web service endpoint (with the hostname of `myapp-web`).

The moral of the story is to try keeping some visualizations nearby that can help you think through what your network is actually doing, and how the Services on it are being reached. It's also about not feeling too bad about it when you make a mistake. Changing our working mental models of how all this is supposed to go is no small feat! And never forget: mistakes are valuable learning opportunities.