FROM phusion/baseimage

MAINTAINER Mian Muhammad <se.mianasif@gmail.com>

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive
RUN export LANG=C.UTF-8

RUN apt-get -y update
RUN apt-get -y upgrade

RUN apt-get -y install python-software-properties pwgen python-setuptools curl git unzip vim \
            openssl git-core htop rsyslog zip vim vim-common curl multitail sysvbanner figlet python-pip zsh wget telnet libpcre3 libpcre3-dev ssh

RUN apt-get install -y openssh-server

# Install AWSCLI
RUN pip install awscli

RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout

RUN mkdir -p /var/run/sshd
# Supervisor Config

RUN sudo useradd anmol
RUN passwd -d anmol
RUN passwd -d root
RUN echo "PermitEmptyPasswords yes" >> /etc/ssh/sshd_config
RUN echo "anmol ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
RUN echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
RUN chsh -s `which bash` anmol
RUN usermod -d /home/anmol anmol
RUN mkdir -p /home/anmol
RUN mkdir -p /home/anmol/.ssh
ADD ./id_rsa		 /home/anmol/.ssh/authorized_keys
RUN chown -R anmol:anmol /home/anmol
RUN chmod -R 777 /home/anmol

# Install zsh
ADD ./files/install-zsh.sh /root/install-zsh.sh
ADD ./files/install-zsh.sh /home/anmol/install-zsh.sh

RUN chmod +x /root/install-zsh.sh
RUN chmod +x /home/anmol/install-zsh.sh
RUN sh /root/install-zsh.sh

RUN su - anmol -c "sh /home/anmol/install-zsh.sh"

#RUN echo 'root:p' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile


RUN rm  /root/.zshrc
ADD ./files/zshrc /root/.zshrc
ADD ./files/zshrc //home/anmol/.zshrc

RUN chsh -s `which zsh` anmol
RUN chsh -s `which zsh`

RUN chmod -R 755 /usr/local/share/zsh/site-functions


RUN apt-get update
RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:webupd8team/java
RUN apt-get update

# automatically accept oracle license
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
# and install java 8 oracle jdk
RUN apt-get -y install oracle-java8-installer && apt-get clean
RUN update-alternatives --display java
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Define default command.

EXPOSE 22
EXPOSE 5566
CMD ["/usr/sbin/sshd", "-D"]
